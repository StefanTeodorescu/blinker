#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
TOOLS="$SCRIPT_PATH/../../.tools/"
BUILD_GEM="$TOOLS/build-gem.sh"
PKG_GEM="$TOOLS/package-gem.sh"

DIR="`mktemp -d`"
BLINKER_WEB="$("$BUILD_GEM" "$SCRIPT_PATH/blinker-web.gemspec" "$DIR")"
"$PKG_GEM" "$DIR"/"$BLINKER_WEB" \
           -d blinker-utils -d supervisor \
           --before-install "$TOOLS"/deb-hooks/create-blinker-user.sh \
           --after-install "$TOOLS"/deb-hooks/exceptions-dir-permissions.sh \
           --empty-directory /var/lib/blinker/exceptions \
           "$SCRIPT_PATH"/config/web.yml=etc/blinker/web.yml \
           "$SCRIPT_PATH"/config/blinker-web.conf=etc/supervisor/conf.d/blinker-web.conf
rm -rf "$DIR"
