#!/bin/sh --
#
# nt_recompress.sh: recompress a Windows NT FAT16 disk image
# by pts@fazekas.hu at Wed Jul 29 01:23:03 CEST 2020
#

set -ex
cd "${0%/*}"

for NTD in "$@"; do
  mtools -c mcopy --version
  test -f "$NTD".img.bak || cp "$NTD".img "$NTD".img.bak
  test -f "$NTD".bsb || dd if="$NTD".img skip=32318 bs=1 count=450 of="$NTD".bsb
  mkdir "$NTD".rec
  # 7z gets confused by WINNT being a file.
  # (cd "$NTD".rec && 7z x ../"$NTD".img.bak) || exit "$?"
  mtools -c mcopy -i "$NTD".img.bak@@32256 -s :: "$NTD".rec
  rm -f $(find "$NTD".rec -iname temppf.sys)
  dd if=/dev/zero of="$NTD".img bs=1M count=140
  gzip -cd <fat16hd.img.gz >"$NTD".fat16hd.img
  dd if="$NTD".fat16hd.img of="$NTD".img bs=8K conv=notrunc  # 140 MiB, 1 partition.
  rm -f "$NTD".fat16hd.img
  dd if="$NTD".bsb seek=32318 bs=1 count=450 of="$NTD".img conv=notrunc
  # We lose permission bits, ownership, hidden--system attribute bits etc.
  mtools -c mcopy -i "$NTD".img@@32256 "$NTD".rec/* -s ::
  rm -rf "$NTD".rec
  xz -8 <"$NTD".img >"$NTD".img.xz
done

: "$0" OK.
