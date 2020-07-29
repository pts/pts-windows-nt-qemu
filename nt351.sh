#!/bin/sh --
#
# nt351.sh: Install and run Windows NT 3.5 in QEMU on Linux
# by pts@fazekas.hu at Tue Jul 28 21:12:36 CEST 2020
#

set -ex
cd "${0%/*}"

if test "$1" = format-floppy; then
  dd if=/dev/zero bs=81920 count=54 of=floppy.img
  mtools -c mformat -i floppy.img -h 2 -s 54 -d 1 -t 80
  exit
fi

if ! test -f nt351.img && test -f nt351.img.xz; then
  xzdec <nt351.img.xz >nt351.img.tmp || xz -cd <nt351.img.xz >nt351.img.tmp
  mv nt351.img.tmp nt351.img
fi
if ! test -f nt351.img; then
  if ! test -f nt351.cd/I386/WINNT.EXE; then
    test -d nt351.cd || mkdir nt351.cd
    test -f I386/WINNT.EXE && mv -t nt351.cd I386
    if ! test -f nt351.cd/I386/WINNT.EXE; then
      set -ex
      echo "$0: fatal: extract Windows NT 3.5 install CD to nt351.cd; example: 7z x 'Microsoft Windows NT 3.51 Workstation.iso' I386" >&2
      exit 2
    fi
  fi
  #!!test -f amdpcnet.nt/OEMSETUP.INF
  mtools -c mcopy --version

  rm -rf nt351.dir
  mkdir nt351.dir nt351.dir/\$WIN_NT\$.~BT nt351.dir/\$WIN_NT\$.~BT/SYSTEM32 nt351.dir/\$WIN_NT\$.~LS

  #cat >nt351.dir/NT35 <<'EOF'
  #EOF

  #cat >nt351.dir/WINNT <<'EOF'
  #EOF

  cat >nt351.dir/BOOT.INI <<'EOF'
[Boot Loader]
Timeout=5
Default=C:\$WIN_NT$.~BT\BOOTSECT.DAT
[Operating Systems]
C:\$WIN_NT$.~BT\BOOTSECT.DAT = "Windows NT 3.51 Installation/Upgrade"
EOF

  cat >nt351.dir/\$WIN_NT\$.~LS/SIZE.SIF <<'EOF'
[Data]
Size = 39490048
EOF

  cat >nt351.dir/\$WIN_NT\$.~BT/WINNT.SIF <<'EOF'
[Data]
MsDosInitiated = 1
Floppyless = 1
EOF

  # perl -pe 's@(\x27.*\x27) #, keep (\x27.*\x27)@$2 $1@'
  gzip -cd <nt351.cp.sh.gz >nt351.cp.sh
  # TODO(pts): Generate this file automatically by applying an extension map.
  source ./nt351.cp.sh || exit "$?"
  rm -f nt351.cp.sh

  dd if=/dev/zero of=nt351.img.tmp bs=1M count=140
  gzip -cd <fat16hd.img.gz >nt351.fat16hd.img
  dd if=nt351.fat16hd.img of=nt351.img.tmp bs=8K conv=notrunc  # 140 MiB, 1 partition.
  rm -f nt351.fat16hd.img
  # AMD PCnet Ethernet driver built in, no need for external driver.
  #mtools -c mmd -i nt351.img.tmp@@32256 ::AMDPCNET.NT
  #mtools -c mcopy -i nt351.img.tmp@@32256 -s amdpcnet.nt/* ::AMDPCNET.NT/
  #mtools -c mcopy -i nt351.img.tmp@@32256 boot/* ::
  #dd if=bootnt351.bs bs=1 seek=32318 skip=62 count=450 of=nt351.img.tmp conv=notrunc
  dd if=nt351.img.tmp skip=32256 bs=1 count=62 of=nt351.bs
  dd if=nt351.cd/I386/SETUPDD.SYS skip=139486 bs=1 seek=62 count=450 of=nt351.bs
  # Overwrite the boot sector in nt351.img.tmp with NTLDR (not $LDR$).
  dd if=nt351.bs skip=62 bs=1 seek=32318 count=450 of=nt351.img.tmp conv=notrunc
  echo '$LDR$' >nt351.setupldr
  dd if=nt351.setupldr bs=1 seek=476 count=5 of=nt351.bs conv=notrunc
  cp -a nt351.bs nt351.dir/\$WIN_NT\$.~BT/BOOTSECT.DAT
  mtools -c mcopy -i nt351.img.tmp@@32256 -s nt351.dir/* ::
  rm -rf nt351.bs nt351.setupldr nt351.dir
  mv nt351.img.tmp nt351.img
fi

if test -f nt351.floppy.img; then FDARGS='-drive file=nt351.floppy.img,format=raw,if=floppy'
elif test -f floppy.img; then FDARGS='-drive file=floppy.img,format=raw,if=floppy'
else FDARGS=''
fi

if test -d drived; then DDARGS='-drive file=fat:rw:drived,format=raw'
else DDARGS=
fi

qemu-system-i386 -L pc -cpu 486 -m 64 -vga cirrus -drive file=nt351.img,format=raw -net nic,model=pcnet -net user -soundhw sb16,pcspk $FDARGS $DDARGS

: "$0" OK.
