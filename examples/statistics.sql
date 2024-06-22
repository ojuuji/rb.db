.output statistics.txt
.bail ON
.mode line

-- Various statistics.

SELECT datetime(value, 'unixepoch') db_version
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

SELECT value schema_version
  FROM rb_db_lov
 WHERE key = 'schema_version';

.print
.print parts:

SELECT count(*) count
  FROM parts;

SELECT min(length(part_num))
     , 'https://rebrickable.com/parts/' || part_num || '/' 'min_len_part_num e.g.'
  FROM parts;

SELECT max(length(part_num))
     , 'https://rebrickable.com/parts/' || part_num || '/' 'max_len_part_num e.g.'
  FROM parts;

SELECT count(*) 'part_relationships count'
  FROM part_relationships;

SELECT count(*) 'part_rels_resolved count'
  FROM part_rels_resolved;

SELECT count(*) 'part_rels_extra count'
  FROM part_rels_extra;

.print
.print sets:

SELECT count(*) count
  FROM sets;

SELECT min(length(set_num))
     , 'https://rebrickable.com/sets/' || set_num || '/' 'min_len_set_num e.g.'
  FROM sets;

SELECT max(length(set_num))
     , 'https://rebrickable.com/sets/' || set_num || '/' 'max_len_set_num e.g.'
  FROM sets;

SELECT min(length(img_url))
     , max(length(img_url))
  FROM sets;

.print
.print minifigs:

SELECT count(*) count
  FROM minifigs;

SELECT min(length(img_url))
     , max(length(img_url))
  FROM minifigs;

.print
.print inventories:

SELECT count(*) count
  FROM inventories;

SELECT count(DISTINCT set_num) 'distinct count'
  FROM inventories;

SELECT max(inventories.version)
     , 'https://rebrickable.com/sets/' || set_num || '/' set_num_with_max_version
  FROM inventories;

SELECT min(length(inventory_parts.img_url))
     , max(length(inventory_parts.img_url))
  FROM inventory_parts;

SELECT count(*) 'inventory_parts count'
  FROM inventory_parts;
