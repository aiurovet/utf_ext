#!/bin/sh

set -e

RPT=${1:-65535}
DIR=$(dirname "${0}")

echo "Creating UTF no-BOM"

cat <<EOT > "${DIR}/utf.txt"
Abc
Абвг
Ⴥն๒
俰𐡁ℵ𝒜
ௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌௌ
EOT

echo "Creating UTF-8"

awk 'BEGIN {
  print "\xEF\xBB\xBF";
} {
  for (i = 0; i < repeats; i++) {
    print $0;
  }
}' "repeats=${RPT}" "${DIR}/utf.txt" > "${DIR}/utf8.txt"

echo "Creating UTF-16xx and UTF-32xx"

iconv -f UTF-8 -t UTF-16LE "${DIR}/utf8.txt" > "${DIR}/utf16le.txt"
iconv -f UTF-8 -t UTF-16BE "${DIR}/utf8.txt" > "${DIR}/utf16be.txt"
iconv -f UTF-8 -t UTF-32LE "${DIR}/utf8.txt" > "${DIR}/utf32le.txt"
iconv -f UTF-8 -t UTF-32BE "${DIR}/utf8.txt" > "${DIR}/utf32be.txt"

echo "Finished"
