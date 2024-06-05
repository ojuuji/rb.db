#! /bin/bash -eu

which curl gzip python sqlite3 > /dev/null

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
mkdir -p data

TS="$(date +%s)"

for TABLE in {themes,colors,parts,part_{categories,relationships},elements,sets,minifigs,inventories,inventory_{parts,sets,minifigs}}.csv; do
	if [[ -f data/$TABLE ]]; then
		echo ":: skipped downloading (already exists) $TABLE"
	else
		echo ":: downloading $TABLE ..."
		curl -s "https://cdn.rebrickable.com/media/downloads/${TABLE}.gz?${TS}" | gzip -cd > data/$TABLE
	fi
done

echo ":: sqlite version: $(sqlite3 -version) (exe), $(python -c 'import sqlite3; print(sqlite3.sqlite_version)') (python)"

echo ":: applying schema ..."
sqlite3 data/rb.db < schema.sql

python import.py
python gen_colors_order.py
python gen_part_rels_resolved.py

echo ":: done"
