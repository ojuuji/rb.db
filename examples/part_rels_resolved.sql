.output part_rels_resolved.csv
.bail ON
.mode csv
.headers ON

-- `part_rels_resolved.csv` in the same format as `part_relationships.csv` from Rebrickable.

SELECT *
  FROM part_rels_resolved
 ORDER BY rel_type, child_part_num
