#!/bin/bash

GEM_DIR="$(dirname "$1")"
GEM_SPEC="$(basename "$1")"
GEM_BASE="$(basename "$1" .gemspec)"

pushd "$GEM_DIR" &> /dev/null
gem build "$GEM_SPEC" | grep 'File: ' | awk -F': ' '{print $2}'
find . -xtype f -name "$GEM_BASE-*.gem" -exec mv {} "$2" \; &> /dev/null
popd &> /dev/null
