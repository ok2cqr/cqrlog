#!/bin/bash

# Build a binary .rpm (Qt6) from rpm/cqrlog.spec.
#
# Requirements:
#   * run from the root of the repository (a git checkout)
#   * rpm-build plus the spec's BuildRequires:
#       sudo dnf install rpm-build dnf-plugins-core
#       sudo dnf builddep rpm/cqrlog.spec

set -euo pipefail

VERSION=$(./tools/get_version.sh)
echo "You are building CQRLOG version: $VERSION"

FINAL=$(pwd)
WDIR=$(mktemp -d)
trap 'rm -rf "$WDIR"' EXIT
mkdir -p "$WDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Source tarball from the tracked files (working-tree content, so local
# uncommitted edits are included, but no build output or stray files)
git ls-files -z | tar --null -T - -czf "$WDIR/SOURCES/cqrlog-$VERSION.tar.gz" \
    --transform "s,^,cqrlog-$VERSION/,"

rpmbuild -bb \
    --define "_topdir $WDIR" \
    --define "cqr_version $VERSION" \
    rpm/cqrlog.spec

find "$WDIR/RPMS" -name '*.rpm' -exec mv -f {} "$FINAL" \;
ls -lh "$FINAL"/cqrlog-*.rpm
echo "Build is a success"
