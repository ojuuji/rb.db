.bail ON

/*
  Original Rebrickable tables
*/

DROP TABLE IF EXISTS colors;
DROP INDEX IF EXISTS colors_name_idx;

DROP TABLE IF EXISTS themes;
DROP INDEX IF EXISTS themes_parent_id_idx;

DROP TABLE IF EXISTS part_categories;

DROP TABLE IF EXISTS parts;
DROP INDEX IF EXISTS parts_part_cat_id_idx;
DROP INDEX IF EXISTS parts_part_material_idx;

DROP TABLE IF EXISTS part_relationships;
DROP INDEX IF EXISTS part_relationships_rel_type_idx;
DROP INDEX IF EXISTS part_relationships_child_part_num_idx;
DROP INDEX IF EXISTS part_relationships_parent_part_num_idx;

DROP TABLE IF EXISTS elements;
DROP INDEX IF EXISTS elements_part_num_color_id_idx;

DROP TABLE IF EXISTS minifigs;

DROP TABLE IF EXISTS sets;
DROP INDEX IF EXISTS sets_year_idx;
DROP INDEX IF EXISTS sets_theme_id_idx;

DROP TABLE IF EXISTS inventories;
DROP INDEX IF EXISTS inventories_set_num_version_idx;

DROP TABLE IF EXISTS inventory_minifigs;
DROP INDEX IF EXISTS inventory_minifigs_inventory_id_idx;
DROP INDEX IF EXISTS inventory_minifigs_fig_num_idx;

DROP TABLE IF EXISTS inventory_parts;
DROP TABLE IF EXISTS inventory_parts_inventory_id_idx;
DROP INDEX IF EXISTS inventory_parts_part_num_color_id_idx;

DROP TABLE IF EXISTS inventory_sets;
DROP TABLE IF EXISTS inventory_sets_inventory_id_idx;
DROP INDEX IF EXISTS inventory_sets_set_num_idx;

/*
  Technical table to satisfy inventories.set_num foreign key constraint
*/

DROP TABLE IF EXISTS set_nums;
DROP TRIGGER IF EXISTS insert_set_num;
DROP TRIGGER IF EXISTS insert_fig_num;
