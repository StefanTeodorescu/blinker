#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"

VERSION=$(date -d @`stat -c '%Y' "$SCRIPT_PATH/capture.py"` '+%Y%m%d%H%M%S')

DIR="$(mktemp -d)"
pushd "$DIR" &>/dev/null

mkdir -p usr/bin opt/blinker
ln -s /usr/lib/chromium-browser/chromedriver usr/bin/chromedriver
cp "$SCRIPT_PATH/capture.py" opt/blinker

popd &>/dev/null

fpm -C "$DIR" -t deb -s dir -n blinker-capgen \
    --log warn \
    --description "Blinker - tools for generating packet captures" \
    --version "$VERSION" \
    -d mininet -d bridge-utils \
    -d chromium-browser -d chromium-chromedriver -d xvfb \
    usr/bin opt/blinker |
grep -v "Debian packaging tools generally labels all files"

rm -rf "$DIR"
