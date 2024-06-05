.bail ON

CREATE INDEX colors_order_color_id_idx ON colors_order(color_id);

CREATE INDEX part_rels_resolved_rel_type_child_part_num_idx ON part_rels_resolved(rel_type, child_part_num);
