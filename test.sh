#!/bin/zsh

cd /Library/Developer/CommandLineTools/SDKs/MacOSX26.0.sdk/usr/share/man/
cd "man$1"

# for file in "$@"; do
for file in *; do
  # Remove the extension (handles filenames with multiple dots by removing only the last part)
  base="${file%.*}"

  open "manml:/$base/$1"

  # Wait for any key (or Enter)
  read -k1 -s -r "?."
done

