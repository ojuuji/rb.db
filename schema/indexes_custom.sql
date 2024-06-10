.bail ON

CREATE INDEX color_props_color_id_idx ON color_props(color_id);

CREATE INDEX part_rels_resolved_rel_type_child_part_num_idx ON part_rels_resolved(rel_type, child_part_num);
