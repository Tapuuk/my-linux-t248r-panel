#!/bin/sh
# Builds my-linux-t248r-panel_<version>-<release>_all.deb with plain dpkg-deb.
# Usage: packaging/deb/build-deb.sh [output dir]    (DEB_RELEASE overrides the "-1")
set -eu

here=$(cd "$(dirname "$0")" && pwd)
top=$(cd "$here/../.." && pwd)
name=my-linux-t248r-panel
version=$(sed -n 's/^VERSION = "\(.*\)"/\1/p' "$top/t248rpanel/__init__.py")
release=${DEB_RELEASE:-1}
out=${1:-$top/dist}
[ -n "$version" ] || { echo "could not read VERSION" >&2; exit 1; }
command -v dpkg-deb >/dev/null || { echo "dpkg-deb not found" >&2; exit 1; }

mkdir -p "$out"
out=$(cd "$out" && pwd)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT INT TERM
root=$stage/root
docdir=/usr/share/doc/$name

make -C "$top" install DESTDIR="$root" PREFIX=/usr LICENSEDIR="$docdir"

# Debian keeps the license as doc/<package>/copyright.
{
    echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
    echo "Upstream-Name: $name"
    echo "Source: https://github.com/Tapuuk/my-linux-t248r-panel"
    echo
    echo "Files: *"
    echo "Copyright: 2026 Tapuuk"
    echo "License: MIT"
    echo
    echo "Files: t248rpanel/assets/fonts/Rubik.ttf"
    echo "Copyright: 2015 The Rubik Project Authors"
    echo "License: OFL-1.1"
    echo " The full text is in /usr/lib/$name/t248rpanel/assets/fonts/Rubik-OFL.txt."
    echo
    echo "Files: t248rpanel/assets/fonts/MaterialSymbolsRounded.ttf"
    echo "Copyright: Google LLC"
    echo "License: Apache-2.0"
    echo " On Debian systems the full text is in /usr/share/common-licenses/Apache-2.0."
    echo
    echo "License: MIT"
    sed -e 's/^$/./' -e 's/^/ /' "$root$docdir/LICENSE"
} > "$root$docdir/copyright"
rm "$root$docdir/LICENSE"

chmod 755 "$root"
mkdir -m 755 "$root/DEBIAN"
size=$(du -sk --apparent-size "$root" | cut -f1)
sed -e "s/@VERSION@/$version-$release/" -e "s/@SIZE@/$size/" "$here/control.in" > "$root/DEBIAN/control"
(cd "$root" && find usr -type f -print0 | sort -z | xargs -0 md5sum) > "$root/DEBIAN/md5sums"
chmod 644 "$root/DEBIAN/control" "$root/DEBIAN/md5sums"

deb=$out/${name}_${version}-${release}_all.deb
dpkg-deb --root-owner-group -Zxz --build "$root" "$deb"
echo "$deb"
