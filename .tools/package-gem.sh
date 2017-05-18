#!/bin/bash

if [[ "" == "$1" ]]; then
    echo "The first argument must be the gem file to package."
    exit 1
fi

if [[ ! -e "$1" ]]; then
    echo "The file $1 does not exist."
    exit 1
fi

GEM_PATH="$1"
shift

DIR="$(mktemp -d)"
FILE="$(basename "$GEM_PATH")"
GEM="$(gem specification "$GEM_PATH" name | head -n 1 | cut -b 5-)"
GEM_SUMMARY="$(gem specification "$GEM_PATH" summary | head -n 1 | cut -b 5-)"
GEM_AUTHOR="$(gem specification "$GEM_PATH" author | head -n 1 | cut -b 5-)"
GEM_LICENSE="$(gem specification "$GEM_PATH" license | head -n 1 | cut -b 5-)"
GEM_VERSION="$(gem specification "$GEM_PATH" version | grep ': ' | awk -F': ' '{print $2}')"

cp "$GEM_PATH" "$DIR/"
mkdir "$DIR/empty"

pushd "$DIR" &>/dev/null
mkdir -p opt/installed-gems
mv "$FILE" opt/installed-gems

echo -e "#!/bin/bash\n" | tee "$DIR"/{pre,post}{inst,rm} >/dev/null
cat >>"$DIR/postint" <<README
cat > /opt/installed-gems/README <<EOF
Ruby gems and the Debian package system are not really compatible. The standard
solution is the 'rubygems-integration' Debian package, which essentially merges
the lib/ directories of all installed gems under /usr/lib/ruby/vendor_ruby.
However, this approach does not cope particularly well with gems that may
contain files other than in their lib, bin, and ext directories. The toolkit for
building these DEBs, gem2deb, is also quite inflexible and scarcely documented.
Therefore blinker DEB packages do not use 'rubygems-integration', but instead
contain just them .gem file itself, which is stored in this directory, and then
installed/uninstalled using the standard gem utility when the Debian package is
installed/uninstalled.
EOF
README

echo "gem install -N '/opt/installed-gems/$FILE'" >> "$DIR/postinst"
echo "gem uninstall -xI '$GEM'" >> "$DIR/prerm"

declare -a FPM_ARGS

while [[ "$#" != "0" ]]; do
    if [[ "$1" == "--after-install" || "$1" == "--post-install" ]]; then
        cat "$2" >> "$DIR/postinst"
        shift 2
    elif [[ "$1" == "--before-install" || "$1" == "--pre-install" ]]; then
        cat "$2" >> "$DIR/preinst"
        shift 2
    elif [[ "$1" == "--after-remove" || "$1" == "--post-uninstall" ]]; then
        cat "$2" >> "$DIR/postrm"
        shift 2
    elif [[ "$1" == "--before-remove" || "$1" == "--pre-uninstall" ]]; then
        cat "$2" >> "$DIR/prerm"
        shift 2
    elif [[ "$1" == "--empty-directory" ]]; then
        FPM_ARGS[${#FPM_ARGS[@]}]="$DIR/empty/=$2"
        shift 2
    else
        FPM_ARGS[${#FPM_ARGS[@]}]="$1"
        shift
    fi
done

popd &>/dev/null

fpm \
    -s dir -t deb \
    --log warn \
    -d ruby -d ruby-dev -d build-essential \
    -n "$GEM" --description "$GEM_SUMMARY" --version "$GEM_VERSION" \
    --vendor "$GEM_AUTHOR" --license "$GEM_LICENSE" \
    --before-install "$DIR/preinst" --after-install "$DIR/postinst" \
    --before-remove "$DIR/prerm" --after-remove "$DIR/postrm" \
    "${FPM_ARGS[@]}" "${GEM_PATH}=opt/installed-gems/$FILE" |
grep -v "Debian packaging tools generally labels all files"

rm -rf "$DIR"
