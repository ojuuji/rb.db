#! /bin/bash

set -eu

SRCDIR="$(cd "$(dirname "$(readlink -f "$BASH_SOURCE")")/../examples" && pwd)"
OUTDIR="$(readlink -f "${SRCDIR}/../docs/examples")"

mkdir -p "$OUTDIR"

for SRC in "$SRCDIR"/*.sql; do
	NAME="$(basename "$SRC")"
	echo ":: processing $NAME ..."

	cp -f "$SRC" "$OUTDIR"
	(cd "$OUTDIR" && sqlite3 ../../data/rb.db < "$NAME")
done
