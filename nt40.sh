#!/bin/sh --
#
# nt40.sh: Install and run Windows NT 3.51 in QEMU on Linux
# by pts@fazekas.hu at Tue Jul 28 21:32:05 CEST 2020
#

set -ex
cd "${0%/*}"

if ! test -f nt40.img && test -f nt40.img.xz; then
  xzdec <nt40.img.xz >nt40.img.tmp || xz -cd <nt40.img.xz >nt40.img.tmp
  mv nt40.img.tmp nt40.img
fi
if ! test -f nt40.img; then
  if ! test -f nt40.iso; then
    set -ex
    echo "$0: fatal: save Windows NT 4.0 install CD image to nt40.iso"
    exit 2
  fi
  dd if=/dev/zero of=nt40.img bs=1M count=140
  XARGS='-cdrom nt40.iso -boot c'
else
  XARGS=
fi

qemu-system-i386 -L pc -cpu pentium -m 64 -vga cirrus -drive file=nt40.img,format=raw -net nic,model=pcnet -net user -soundhw sb16,pcspk $XARGS

: "$0" OK.
