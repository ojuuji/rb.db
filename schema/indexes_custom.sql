.bail ON

CREATE INDEX color_properties_color_id_idx ON color_properties(color_id);

CREATE INDEX similar_color_ids_ref_id_idx ON similar_color_ids(ref_id);

CREATE INDEX part_rels_resolved_rel_type_child_part_num_idx ON part_rels_resolved(rel_type, child_part_num);
