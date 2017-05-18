#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"

"$SCRIPT_PATH/ctf/package-blinker-ctf.sh"
"$SCRIPT_PATH/filestore/package-blinker-filestore.sh"
"$SCRIPT_PATH/web/package-blinker-web.sh"
