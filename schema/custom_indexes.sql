.bail ON

CREATE INDEX part_rels_resolved_rel_type_child_part_num_idx ON part_rels_resolved(rel_type, child_part_num);

CREATE INDEX part_rels_extra_rel_type_child_part_num_idx ON part_rels_extra(rel_type, child_part_num);
