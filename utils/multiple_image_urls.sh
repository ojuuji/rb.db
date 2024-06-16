#! /bin/bash

set -u

WORKDIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

cat <<EOF | sqlite3 -table -echo "$WORKDIR/../data/rb.db"

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

SELECT DISTINCT part_num, color_id, img_url
           FROM inventory_parts
   NATURAL JOIN ( SELECT part_num, color_id
                    FROM ( SELECT *
                             FROM inventory_parts
                         GROUP BY part_num, color_id, img_url
                         ) x
                GROUP BY 1, 2
                  HAVING count(*) > 1
                ) y;
EOF
