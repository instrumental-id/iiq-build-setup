#!/usr/bin/env bash
#
# Copies versioned IIQ JARs (as stored in the source repository, e.g.
# identityiq-8.4.jar) into a directory under the unversioned names that
# IIQ builds expect (e.g. identityiq.jar).
#
# Usage: stage.sh <source-dir> <iiq-version> <dest-dir>
#
# Environment:
#   IIQ_JARS           space-separated base names that must exist
#   IIQ_OPTIONAL_JARS  space-separated base names copied only if present

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <source-dir> <iiq-version> <dest-dir>" >&2
    exit 2
fi

src="$1"
version="$2"
dest="$3"

read -r -a required <<< "${IIQ_JARS:-identityiq connector-bundle-identityiq}"
read -r -a optional <<< "${IIQ_OPTIONAL_JARS:-}"

mkdir -p "$dest"

for name in "${required[@]}"; do
    jar="$src/$name-$version.jar"
    if [ ! -f "$jar" ]; then
        echo "::error::Missing required JAR: $name-$version.jar"
        exit 1
    fi
    cp "$jar" "$dest/$name.jar"
    echo "Staged $name-$version.jar -> $dest/$name.jar"
done

for name in "${optional[@]}"; do
    jar="$src/$name-$version.jar"
    if [ -f "$jar" ]; then
        cp "$jar" "$dest/$name.jar"
        echo "Staged $name-$version.jar -> $dest/$name.jar"
    fi
done
