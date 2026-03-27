#! /bin/bash

set -eu

WORKDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

for AR in xz gz zip; do
	SIZE="$(gh release view latest --json assets --jq '.assets | map(select(.name == "rb.db.'$AR'")) | .[].size')"
	SIZE="$(printf "%.1fM" "$((SIZE / 1024 / 1024)).$((SIZE * 1000 / 1024 / 1024 % 1000))")"
	sed -i "s/<!--DB_${AR^^}_SIZE-->/$SIZE/" "$WORKDIR/../docs/_includes/download.html"
done

DATE="$(gh release view latest --json name --jq '.name' | grep -Po '\d{4}-\d\d-\d\d \d\d:\d\d')"
sed -i "s/<!--DB_DATE-->/$DATE/" "$WORKDIR/../docs/_includes/download.html"
