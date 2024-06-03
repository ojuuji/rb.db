#! /bin/bash -eu

which curl gzip python sqlite3 > /dev/null

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
mkdir -p data

for TABLE in {themes,colors,parts,part_{categories,relationships},elements,sets,minifigs,inventories,inventory_{parts,sets,minifigs}}.csv; do
	if [[ ! -f data/$TABLE ]]; then
		echo ":: downloading $TABLE ..."
		curl -s https://cdn.rebrickable.com/media/downloads/${TABLE}.gz | gzip -cd > data/$TABLE
	fi
done

echo ":: applying schema ..."
echo "sqlite3 CLI version $(sqlite3 -version)"
sqlite3 data/rb.db < schema.sql

python import.py

echo ":: done"
