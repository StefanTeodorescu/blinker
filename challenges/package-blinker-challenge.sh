#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"

if [[ -z "$1" ]]; then
    echo "First argument must be the challenge name"
    exit 1
fi

CHALLENGE_NAME="$1"
CHALLENGE_DIR="$(readlink -f "$SCRIPT_PATH/../challenges/$CHALLENGE_NAME")"

if [[ ! -d "$CHALLENGE_DIR" ]]; then
    echo "Challenge directory ($CHALLENGE_DIR) does not exist"
    exit 1
fi

PKG_NAME="$(echo "$CHALLENGE_NAME" | sed 's/_/-/g')"
NICE_NAME="$(basename "`find "$CHALLENGE_DIR/" -name '*.chall' | tail -n 1`" .chall)"
VERSION=$(date -d @`find "$CHALLENGE_DIR" | xargs stat -c '%Y' | sort -n | tail -n 1` '+%Y%m%d%H%M%S')
DEPENDENCIES=$([[ -e "$CHALLENGE_DIR/dependencies" ]] && cat "$CHALLENGE_DIR/dependencies" | sed 's/^/-d /' | xargs || echo)

DIR="`mktemp -d`"
pushd "$DIR" &>/dev/null

mkdir -p usr/share/blinker/challenges
cp -a "$CHALLENGE_DIR" usr/share/blinker/challenges

fpm -t deb -s dir -n "blinker-challenge-$PKG_NAME" \
    --description "Blinker challenge: $NICE_NAME" \
    --version "$VERSION" \
    $DEPENDENCIES \
    usr/share/blinker/challenges |
grep -v "Debian packaging tools generally labels all files"

popd &>/dev/null
mv "$DIR"/*.deb .
rm -rf "$DIR"
