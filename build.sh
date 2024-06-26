#! /bin/bash

set -eu

if [[ $# -gt 1 || $# -eq 1 && "$1" != "-rbonly" ]]; then
	echo -e "build.sh: invalid argument(s)\nusage: build.sh [-rbonly]" >&2
	exit 1
fi

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

echo ":: creating Rebrickable tables ..."

rm -f data/rb.db
sqlite3 data/rb.db < schema/rb_tables.sql

python build/import_rb_tables.py

echo ":: creating indexes on Rebrickable tables ..."
sqlite3 data/rb.db < schema/rb_indexes.sql

if [[ $# -eq 0 ]]; then
	echo ":: creating custom tables ..."
	sqlite3 data/rb.db < schema/custom_tables.sql

	python build/gen_color_properties.py
	python build/gen_similar_color_ids.py
	python build/gen_part_rels_resolved.py
	python build/gen_part_rels_extra.py

	echo ":: creating indexes on custom tables ..."
	sqlite3 data/rb.db < schema/custom_indexes.sql
fi

echo ":: running tests ..."

PYTEST_ARGS=(-q --pylama)
[[ $# -ne 0 ]] && PYTEST_ARGS+=(-m 'not custom_schema')
pytest "${PYTEST_ARGS[@]}"

echo ":: done"
