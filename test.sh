#!/bin/zsh

cd /Library/Developer/CommandLineTools/SDKs/MacOSX26.0.sdk/usr/share/man/
cd "man$1"

# for file in "$@"; do
for file in $2*; do
  # Remove the extension (handles filenames with multiple dots by removing only the last part)
  base="${file%.*}"

  open "manml:/$base/$1"

  osascript -e 'tell application "System Events" to key code 48 using command down'

  # Wait for any key (or Enter)
  read -k1 -s -r "?."
done

