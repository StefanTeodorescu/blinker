#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
BUILD_GEM="$SCRIPT_PATH/../../.tools/build-gem.sh"
PKG_GEM="$SCRIPT_PATH/../../.tools/package-gem.sh"

DIR="`mktemp -d`"
BLINKER_FRAMEWORK="$("$BUILD_GEM" "$SCRIPT_PATH/blinker-framework.gemspec" "$DIR")"
"$PKG_GEM" "$DIR"/"$BLINKER_FRAMEWORK" \
           -d blinker-llvm -d blinker-utils
rm -rf "$DIR"
