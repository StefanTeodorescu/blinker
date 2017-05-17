#!/bin/bash

if [[ "$(ls -A . | wc -l)" != "0" ]]; then
    echo "You will want to run this in an empty directory."
    exit 1
fi

SELF="$(readlink -f "$0")"
SELFDIR="$(dirname "$SELF")"

for component in llvm cfe lld; do
    curl http://releases.llvm.org/4.0.0/${component}-4.0.0.src.tar.xz | tar -xJ
done

for patch in `ls "$SELFDIR"/*.patch | sort`; do
    patch -p1 < "$patch"
done
