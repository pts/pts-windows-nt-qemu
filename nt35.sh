#!/bin/sh --
#
# nt35.sh: Install and run Windows NT 3.5 in QEMU on Linux
# by pts@fazekas.hu at Tue Jul 28 19:43:09 CEST 2020
#

set -ex
cd "${0%/*}"

if test "$1" = format-floppy; then
  dd if=/dev/zero bs=81920 count=54 of=floppy.img
  mtools -c mformat -i floppy.img -h 2 -s 54 -d 1 -t 80
  exit
fi

if ! test -f nt35.img && test -f nt35.img.xz; then
  xzdec <nt35.img.xz >nt35.img.tmp || xz -cd <nt35.img.xz >nt35.img.tmp
  mv nt35.img.tmp nt35.img
fi
if ! test -f nt35.img; then
  if ! test -f nt35.cd/I386/WINNT.EXE; then
    test -d nt35.cd || mkdir nt35.cd
    test -f I386/WINNT.EXE && mv -t nt35.cd I386
    if ! test -f nt35.cd/I386/WINNT.EXE; then
      set -ex
      echo "$0: fatal: extract Windows NT 3.5 install CD to nt35.cd; example: 7z x 'Microsoft Windows NT 3.5 Workstation (3.50.807).iso' I386" >&2
      exit 2
    fi
  fi
  test -f amdpcnet.nt/OEMSETUP.INF
  mtools -c mcopy --version

  rm -rf nt35.dir
  mkdir nt35.dir nt35.dir/\$WIN_NT\$.~BT nt35.dir/\$WIN_NT\$.~BT/SYSTEM32 nt35.dir/\$WIN_NT\$.~LS

  #cat >nt35.dir/NT35 <<'EOF'
  #EOF

  #cat >nt35.dir/WINNT <<'EOF'
  #EOF

  cat >nt35.dir/BOOT.INI <<'EOF'
[Boot Loader]
Timeout=5
Default=C:\$WIN_NT$.~BT\BOOTSECT.DAT
[Operating Systems]
C:\$WIN_NT$.~BT\BOOTSECT.DAT = "Windows NT 3.5 Installation/Upgrade"
EOF

  cat >nt35.dir/\$WIN_NT\$.~LS/SIZE.SIF <<'EOF'
[Data]
Size = 33413632
EOF

  cat >nt35.dir/\$WIN_NT\$.~BT/WINNT.SIF <<'EOF'
[Data]
MsDosInitiated = 1
Floppyless = 1
EOF

  # perl -pe 's@(\x27.*\x27) #, keep (\x27.*\x27)@$2 $1@'
  gzip -cd <nt35.cp.sh.gz >nt35.cp.sh
  # TODO(pts): Generate this file automatically by applying an extension map.
  source ./nt35.cp.sh || exit "$?"
  rm -f nt35.cp.sh

  dd if=/dev/zero of=nt35.img.tmp bs=1M count=140
  gzip -cd <fat16hd.img.gz >nt35.fat16hd.img
  dd if=nt35.fat16hd.img of=nt35.img.tmp bs=8K conv=notrunc  # 140 MiB, 1 partition.
  rm -f nt35.fat16hd.img
  mtools -c mmd -i nt35.img.tmp@@32256 ::AMDPCNET.NT
  mtools -c mcopy -i nt35.img.tmp@@32256 -s amdpcnet.nt/* ::AMDPCNET.NT/
  #mtools -c mcopy -i nt35.img.tmp@@32256 boot/* ::
  #dd if=bootnt35.bs bs=1 seek=32318 skip=62 count=450 of=nt35.img.tmp conv=notrunc
  dd if=nt35.img.tmp skip=32256 bs=1 count=62 of=nt35.bs
  dd if=nt35.cd/I386/SETUPDD.SYS skip=167278 bs=1 seek=62 count=450 of=nt35.bs
  # Overwrite the boot sector in nt35.img.tmp with NTLDR (not $LDR$).
  dd if=nt35.bs skip=62 bs=1 seek=32318 count=450 of=nt35.img.tmp conv=notrunc
  echo '$LDR$' >nt35.setupldr
  dd if=nt35.setupldr bs=1 seek=476 count=5 of=nt35.bs conv=notrunc
  cp -a nt35.bs nt35.dir/\$WIN_NT\$.~BT/BOOTSECT.DAT
  mtools -c mcopy -i nt35.img.tmp@@32256 -s nt35.dir/* ::
  rm -rf nt35.bs nt35.setupldr nt35.dir
  mv nt35.img.tmp nt35.img
fi

if test -f nt35.floppy.img; then FDARGS='-drive file=nt35.floppy.img,format=raw,if=floppy'
elif test -f floppy.img; then FDARGS='-drive file=floppy.img,format=raw,if=floppy'
else FDARGS=''
fi

qemu-system-i386 -L pc -cpu 486 -m 64 -vga cirrus -drive file=nt35.img,format=raw -net nic,model=pcnet -net user -soundhw sb16,pcspk $FDARGS

: "$0" OK.
