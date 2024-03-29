#!/bin/sh --
#
# nt31.sh: Install and run Windows NT 3.1 in QEMU on Linux
# by pts@fazekas.hu at Tue Jul 28 19:50:57 CEST 2020
#

set -ex
cd "${0%/*}"

if test "$1" = format-floppy; then
  # Maximum floppy size for Windows NT 3.1 is 2880 KiB.
  # 2880 KiB also seems to work, but it copies invalid file content.
  #dd if=/dev/zero bs=81920 count=36 of=floppy.img
  #mtools -c mformat -i floppy.img -h 2 -s 36 -d 1 -t 80

  # Maximum floppy size for Windows NT 3.1 is 1440 KiB.
  dd if=/dev/zero bs=81920 count=18 of=floppy.img
  mtools -c mformat -i floppy.img -h 2 -s 18 -d 1 -t 80
  exit
fi

if ! test -f nt31.img && test -f nt31.img.xz; then
  xzdec <nt31.img.xz >nt31.img.tmp || xz -cd <nt31.img.xz >nt31.img.tmp
  mv nt31.img.tmp nt31.img
fi
if ! test -f nt31.img; then
  if ! test -f nt31.cd/I386/WINNT.EXE; then
    test -d nt31.cd || mkdir nt31.cd
    test -f I386/WINNT.EXE && mv -t nt31.cd I386
    HAVE_IMG=; for F in nt31.cd/*[Dd]isk*.img; do HAVE_IMG=1; done
    if test "$HAVE_IMG"; then
      mtools -c mcopy --version
      test -d nt31.cd/I386 || mkdir nt31.cd/I386
      for F in nt31.cd/*[Dd]isk*.img; do
        (cd nt31.cd/I386; mtools -c mcopy -i ../../"$F" -s -n -o :: .)
      done
    fi
    if ! test -f nt31.cd/I386/WINNT.EXE; then
      set -ex
      echo "$0: fatal: extract Windows NT 3.5 install CD to nt31.cd; example: 7z x 'Microsoft Windows NT 3.5 Workstation (3.50.807).iso' I386" >&2
      exit 2
    fi
  fi
  test -f amdpcnet.nt/OEMSETUP.INF
  mtools -c mcopy --version

  rm -rf nt31.dir
  mkdir nt31.dir nt31.dir/\$WIN_NT\$.~LS

  gzip -cd <nt31.cp.sh.gz >nt31.cp.sh
  # TODO(pts): Generate this file automatically by applying an extension map.
  source ./nt31.cp.sh || exit "$?"
  rm -f nt31.cp.sh

  cat >>nt31.dir/TXTSETUP.INF <<'EOF'
[MsDosInitiated]
EOF

  dd if=/dev/zero of=nt31.img.tmp bs=1M count=140
  gzip -cd <fat16hd.img.gz >nt31.fat16hd.img
  dd if=nt31.fat16hd.img of=nt31.img.tmp bs=8K conv=notrunc  # 140 MiB, 1 partition.
  rm -f nt31.fat16hd.img
  mtools -c mmd -i nt31.img.tmp@@32256 ::AMDPCNET.NT
  mtools -c mcopy -i nt31.img.tmp@@32256 -s amdpcnet.nt/* ::AMDPCNET.NT/
  #mtools -c mcopy -i nt31.img.tmp@@32256 boot/* ::
  #dd if=bootnt31.bs bs=1 seek=32318 skip=62 count=450 of=nt31.img.tmp conv=notrunc
  dd if=nt31.img.tmp skip=32256 bs=1 count=62 of=nt31.bs
  dd if=nt31.cd/I386/FATBOOT.BIN skip=62 bs=1 seek=62 count=450 of=nt31.bs
  echo 'SETUPLDR' >nt31.setupldr
  dd if=nt31.setupldr bs=1 seek=476 count=8 of=nt31.bs conv=notrunc
  dd if=nt31.bs skip=62 bs=1 seek=32318 count=450 of=nt31.img.tmp conv=notrunc
  mtools -c mcopy -i nt31.img.tmp@@32256 -s nt31.dir/* ::
  rm -rf nt31.bs nt31.setupldr nt31.dir
  mv nt31.img.tmp nt31.img
fi

if test -f nt31.floppy.img; then FDARGS='-drive file=nt31.floppy.img,format=raw,if=floppy'
elif test -f floppy.img; then FDARGS='-drive file=floppy.img,format=raw,if=floppy'
else FDARGS=''
fi

if test -d drived; then DDARGS='-drive file=fat:rw:drived,format=raw'
else DDARGS=
fi

qemu-system-i386 -L pc -cpu 486 -m 64 -vga cirrus -drive file=nt31.img,format=raw -net nic,model=pcnet -net user -soundhw sb16,pcspk $FDARGS $DDARGS

: "$0" OK.
