.bail ON

DROP TABLE IF EXISTS color_properties;

DROP TABLE IF EXISTS similar_color_ids;
DROP INDEX IF EXISTS similar_color_ids_ref_id_idx;
DROP VIEW IF EXISTS similar_colors;

DROP TABLE IF EXISTS part_rels_resolved;
DROP INDEX IF EXISTS part_rels_resolved_rel_type_child_part_num_idx;

DROP TABLE IF EXISTS part_rels_extra;
DROP INDEX IF EXISTS part_rels_extra_rel_type_child_part_num_idx;

DROP VIEW IF EXISTS ___set_parts_for_stats;
DROP VIEW IF EXISTS part_color_stats;
DROP VIEW IF EXISTS part_stats;
DROP VIEW IF EXISTS color_stats;

DROP TABLE IF EXISTS rb_db_lov;
