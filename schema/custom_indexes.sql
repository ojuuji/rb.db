CREATE INDEX similar_color_ids_ref_id_idx ON similar_color_ids(ref_id);

CREATE UNIQUE INDEX part_rels_resolved_rel_type_child_part_num_idx ON part_rels_resolved(rel_type, child_part_num);

CREATE UNIQUE INDEX part_rels_extra_rel_type_child_part_num_idx ON part_rels_extra(rel_type, child_part_num);
