#! /bin/bash -eu

echo ":: removing old releases ..."

nkeep=11  # latest + 10
last_month=""

while read tag; do
	cur_month="${tag%-*-*-*}"  # 2024-05-17-07-59 -> 2024-05

	if [[ $nkeep -gt 0 ]]; then
		echo "skipped $tag: within nkeep"
		((nkeep--))
	elif [[ "$cur_month" == "$last_month" ]]; then
		echo "deleting $tag ..."
		gh release delete --cleanup-tag --yes "$tag"
	else
		echo "skipped $tag: last in month"
	fi

	last_month="$cur_month"
done < <(gh release list --json tagName --jq ".[].tagName")
