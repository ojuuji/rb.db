#! /bin/bash

set -eu

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

echo ":: sqlite version: $(sqlite3 -version | grep -Po '(\d+\.)+\d+') (exe), $(python -c 'import sqlite3; print(sqlite3.sqlite_version)') (python)"

echo ":: applying schema ..."
rm -f data/rb.db
sqlite3 data/rb.db < schema/tables.sql

python build/import_rb_tables.py

echo ":: creating indexes on rb tables ..."
sqlite3 data/rb.db < schema/indexes_rb.sql

python build/gen_color_properties.py
python build/gen_similar_color_ids.py
python build/gen_part_rels_resolved.py

echo ":: creating indexes on custom tables ..."
sqlite3 data/rb.db < schema/indexes_custom.sql

echo ":: done"
