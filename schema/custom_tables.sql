.bail ON

CREATE TABLE color_properties(
  id INTEGER PRIMARY KEY REFERENCES colors(id),
  sort_pos INTEGER NOT NULL,
  is_grayscale INTEGER CHECK(is_grayscale IN (0, 1))
) STRICT;

CREATE TABLE similar_color_ids(
  ref_id INTEGER NOT NULL REFERENCES colors(id),
  id INTEGER NOT NULL REFERENCES colors(id)
) STRICT;

CREATE VIEW similar_colors(
  ref_id, ref_name, id, name, rgb, is_trans
) AS
  SELECT c.id, c.name, sc.id, sc.name, sc.rgb, sc.is_trans
    FROM similar_color_ids i
    JOIN colors c
      ON c.id = i.ref_id
    JOIN colors sc
      ON sc.id = i.id
ORDER BY i.rowid;

CREATE TABLE part_rels_resolved(
  rel_type TEXT NOT NULL CHECK(rel_type IN ('A', 'M')),
  child_part_num TEXT NOT NULL REFERENCES parts(part_num),
  parent_part_num TEXT NOT NULL REFERENCES parts(part_num)
) STRICT;

CREATE TABLE part_rels_extra(
  rel_type TEXT NOT NULL CHECK(rel_type IN ('A', 'B', 'M', 'P', 'R', 'T')),
  child_part_num TEXT NOT NULL,  -- no foreign key constraints as these may
  parent_part_num TEXT NOT NULL  -- actually not reference actual part numbers
) STRICT;

CREATE TABLE rb_db_lov(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
) STRICT;

INSERT INTO rb_db_lov VALUES('schema_version', '5');
INSERT INTO rb_db_lov VALUES('data_timestamp', strftime('%s', 'now'));
