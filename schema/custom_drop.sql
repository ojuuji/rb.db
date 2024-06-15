.bail ON

DROP TABLE IF EXISTS color_properties;

DROP TABLE IF EXISTS similar_color_ids;
DROP VIEW IF EXISTS similar_colors;

DROP TABLE IF EXISTS part_rels_resolved;
DROP INDEX IF EXISTS part_rels_resolved_rel_type_child_part_num_idx;

DROP TABLE IF EXISTS part_rels_extra;
DROP INDEX IF EXISTS part_rels_extra_rel_type_child_part_num_idx;

DROP TABLE IF EXISTS rb_db_lov;
