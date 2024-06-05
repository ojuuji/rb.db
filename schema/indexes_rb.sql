.bail ON

CREATE INDEX themes_parent_id_idx ON themes(parent_id);

CREATE INDEX parts_part_cat_id_idx ON parts(part_cat_id);
CREATE INDEX parts_part_material_idx ON parts(part_material);

CREATE INDEX part_relationships_rel_type_idx ON part_relationships(rel_type);
CREATE INDEX part_relationships_child_part_num_idx ON part_relationships(child_part_num);
CREATE INDEX part_relationships_parent_part_num_idx ON part_relationships(parent_part_num);

CREATE INDEX elements_part_num_color_id_idx ON elements(part_num, color_id);

CREATE INDEX sets_year_idx ON sets(year);
CREATE INDEX sets_theme_id_idx ON sets(theme_id);

CREATE INDEX inventory_minifigs_fig_num_idx ON inventory_minifigs(fig_num);

CREATE INDEX inventory_parts_part_num_color_id_idx ON inventory_parts(part_num, color_id);

CREATE INDEX inventory_sets_set_num_idx ON inventory_sets(set_num);
