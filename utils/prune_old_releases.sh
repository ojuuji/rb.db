#! /bin/bash

set -eu

echo ":: listing tags to delete ..."

nkeep=10
last_month=""

while read tag; do
	cur_month="${tag%-*-*-*}"  # 2024-05-17-07-59 -> 2024-05

	if [[ "$tag" == latest* ]]; then
		echo "skipped tag '$tag': latest tags are never deleted"

	elif [[ $nkeep -gt 0 ]]; then
		echo "skipped tag '$tag': within nkeep"
		((nkeep--))

	elif [[ "$cur_month" == "$last_month" ]]; then
		echo "deleting tag '$tag' ..."
		gh release delete --cleanup-tag --yes "$tag"

	else
		echo "skipped tag '$tag': last in month"
	fi

	last_month="$cur_month"
done < <(gh release list --json tagName --jq ".[].tagName")
