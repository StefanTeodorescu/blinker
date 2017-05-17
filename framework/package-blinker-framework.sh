#!/bin/bash

SCRIPT="$(readlink -f "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"

"$SCRIPT_PATH/capgen/package-blinker-capgen.sh"
"$SCRIPT_PATH/utils/package-blinker-utils.sh"
"$SCRIPT_PATH/framework/package-blinker-framework.sh"

echo -e "\x1b[33m
====================================================================
| blinker-llvm is not built automatically.                         |
| To build it, follow the instructions in framework/llvm/README.md |
====================================================================
\x1b[39;49m"
