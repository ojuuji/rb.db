#! /bin/bash

set -eu

Release ()
{
	local tagname="$1"
	local relname="$2"

	echo ":: releasing package '$tagname' ..."

	if gh release view "$tagname" &> /dev/null; then
		gh release delete --cleanup-tag --yes "$tagname"
		sleep 13.37
	fi

	gh release create "$tagname" --target master --title "$relname" rb.db.{xz,gz,zip,sha256}
}

echo ":: preparing release ..."

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")/../data"

SCHEMA="$(sqlite3 rb.db "SELECT value FROM rb_db_lov WHERE key = 'schema_version'")"
TS="$(sqlite3 rb.db "SELECT value FROM rb_db_lov WHERE key = 'data_timestamp'")"
DT="$(date -d"@$TS" --utc +'%Y-%m-%d %H:%M')"

Release "${DT//[ :]/-}" "$DT"
Release "latest-v$SCHEMA" "Latest for schema v$SCHEMA ($DT)"
Release "latest" "Latest ($DT)"
