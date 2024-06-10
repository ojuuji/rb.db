#! /bin/bash -u

INFO=""

SIZE="$(gh release view latest --json assets --jq '.assets | map(select(.name == "rb.db.xz")) | .[].size')"
if [[ $SIZE -gt 0 ]]; then
	SIZE=$((SIZE / 1024 * 100 / 1024 ))
	INFO="$((SIZE / 100)).$((SIZE % 100)) MiB"
fi

DATE="$(gh release view latest --json name --jq '.name' | grep -Po '\d{4}-\d\d-\d\d \d\d:\d\d')"
if [[ -n "$DATE" ]]; then
	[[ -n "$INFO" ]] && INFO="$INFO, $DATE" || INFO="$DATE"
fi

if [[ -n "$INFO" ]]; then
	WORKDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
	sed -i "s/<!--DBXZ_INFO-->/($INFO)/" "$WORKDIR/../docs/_includes/download.html"
fi
