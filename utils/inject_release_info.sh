#! /bin/bash -eu

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

SIZE="$(gh release view latest --json assets --jq '.assets | map(select(.name == "rb.db.xz")) | .[].size')"

if [[ $SIZE -gt 0 ]]; then
	SIZE=$((SIZE / 1024 * 100 / 1024 ))
	SIZE="$((SIZE / 100)).$((SIZE % 100)) MiB"
	sed -i "s/<!--DBXZ_SIZE-->/($SIZE)/" "../docs/_includes/download.html"
fi
