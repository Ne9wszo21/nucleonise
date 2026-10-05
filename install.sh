#!/bin/bash

set -e

src="$(cd "$(dirname "$0")/quickshell" && pwd)"
dest="$HOME/.config/quickshell"

echo "installing neuclonize..."

if [ -d "$dest" ]; then
    backup="$HOME/.config/quickshell-backup-$(date +%y%m%d-%h%m%s)"
    echo "backing up existing quickshell config..."
    cp -a "$dest" "$backup"
fi

mkdir -p "$dest"
cp -a "$src"/. "$dest"/

echo "neuclonize installed to $dest"
echo "run 'qs' to start it."
