#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
BUILD_GEM="$SCRIPT_PATH/../../.tools/build-gem.sh"
PKG_GEM="$SCRIPT_PATH/../../.tools/package-gem.sh"

DIR="`mktemp -d`"
BLINKER_UTILS="$("$BUILD_GEM" "$SCRIPT_PATH/blinker-utils.gemspec" "$DIR")"
"$PKG_GEM" "$DIR"/"$BLINKER_UTILS" \
         -d postgresql-server-dev-9.5
rm -rf "$DIR"
