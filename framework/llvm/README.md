To avoid licensing worries, blinker-llvm is distributed as a patch against the
release version of LLVM, Clang, and lld. Running the script
`create-build-tree.sh` in an empty directory will download the base LLVM
release, and apply the patch on top. Afterwards, blinker-llvm can be built using
`release_build.sh` in the build tree.
