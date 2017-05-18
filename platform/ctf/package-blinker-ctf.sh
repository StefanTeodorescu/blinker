#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
TOOLS="$SCRIPT_PATH/../../.tools/"
BUILD_GEM="$TOOLS/build-gem.sh"
PKG_GEM="$TOOLS/package-gem.sh"

DIR="`mktemp -d`"
BLINKER_CTF="$("$BUILD_GEM" "$SCRIPT_PATH/blinker-ctf.gemspec" "$DIR")"
"$PKG_GEM" "$DIR"/"$BLINKER_CTF" \
           -d postgresql-server-dev-9.5 -d blinker-framework -d blinker-utils -d supervisor \
           --before-install "$TOOLS"/deb-hooks/create-blinker-user.sh \
           --empty-directory /usr/share/blinker/challenges \
           "$SCRIPT_PATH"/config/ctf.yml=etc/blinker/ctf.yml \
           "$SCRIPT_PATH"/config/blinker-ctf-jobs.conf=etc/supervisor/conf.d/blinker-ctf-jobs.conf
rm -rf "$DIR"
