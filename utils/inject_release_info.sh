#! /bin/bash

set -eu

WORKDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

for AR in xz gz zip; do
	SIZE="$(gh release view latest --json assets --jq '.assets | map(select(.name == "rb.db.'$AR'")) | .[].size')"
	SIZE=$(((SIZE / 1024 * 10 + 512) / 1024))  # +512 to round e.g. 20.47 to 20.5
	SIZE="$((SIZE / 10)).$((SIZE % 10))M"
	sed -i "s/<!--DB_${AR^^}_SIZE-->/$SIZE/" "$WORKDIR/../docs/_includes/download.html"
done

DATE="$(gh release view latest --json name --jq '.name' | grep -Po '\d{4}-\d\d-\d\d \d\d:\d\d')"
sed -i "s/<!--DB_DATE-->/$DATE/" "$WORKDIR/../docs/_includes/download.html"
