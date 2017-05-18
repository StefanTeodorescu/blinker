#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
TOOLS="$SCRIPT_PATH/../../.tools/"
BUILD_GEM="$TOOLS/build-gem.sh"
PKG_GEM="$TOOLS/package-gem.sh"

DIR="`mktemp -d`"
BLINKER_FILESTORE="$("$BUILD_GEM" "$SCRIPT_PATH/blinker-filestore.gemspec" "$DIR")"
"$PKG_GEM" "$DIR"/"$BLINKER_FILESTORE" \
           -d blinker-utils -d supervisor \
           --before-install "$TOOLS"/deb-hooks/create-blinker-user.sh \
           --after-install "$TOOLS"/deb-hooks/handouts-dir-permissions.sh \
           --after-install "$TOOLS"/deb-hooks/exceptions-dir-permissions.sh \
           --empty-directory /var/lib/blinker/handouts \
           --empty-directory /var/lib/blinker/exceptions \
           "$SCRIPT_PATH"/config/filestore.yml=etc/blinker/filestore.yml \
           "$SCRIPT_PATH"/config/blinker-filestore.conf=etc/supervisor/conf.d/blinker-filestore.conf
rm -rf "$DIR"
