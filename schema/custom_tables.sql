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

CREATE VIEW ___set_parts_for_stats
AS
    WITH set_inventories
      AS (
            SELECT set_num, year, id inventory_id
              FROM sets
              JOIN inventories
             USING (set_num)
             GROUP BY set_num
            HAVING max(version)
         )
         /* parts from sets */
  SELECT set_num, year, part_num, color_id, quantity
    FROM set_inventories
    JOIN inventory_parts
   USING (inventory_id)
   WHERE NOT is_spare
   UNION ALL
         /* parts from minifigs */
  SELECT si.set_num set_num, year, part_num, color_id, (im.quantity * ip.quantity) quantity
    FROM set_inventories si
    JOIN inventory_minifigs im
   USING (inventory_id)
    JOIN inventories i
      ON i.set_num = im.fig_num
    JOIN inventory_parts ip
      ON ip.inventory_id = i.id
   WHERE NOT is_spare;

CREATE VIEW part_color_stats
AS
  SELECT part_num
       , color_id
       , count(DISTINCT set_num) num_sets
       , min(year) min_year
       , max(year) max_year
       , sum(quantity) num_parts
    FROM ___set_parts_for_stats
   GROUP BY 1, 2;

CREATE VIEW part_stats
AS
  SELECT part_num
       , count(DISTINCT set_num) num_sets
       , min(year) min_year
       , max(year) max_year
       , sum(quantity) num_parts
    FROM ___set_parts_for_stats
   GROUP BY 1;

CREATE VIEW part_color_images
AS
  SELECT part_num, color_id, min(img_url) img_url
    FROM inventory_parts
   WHERE img_url IS NOT NULL
   GROUP BY 1, 2;

CREATE VIEW part_images
AS
  SELECT part_num, img_url
    FROM part_color_images
    LEFT OUTER JOIN part_color_stats
   USING (part_num, color_id)
   GROUP BY part_num
  HAVING max(num_parts);

CREATE TABLE rb_db_lov(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
) STRICT;

INSERT INTO rb_db_lov VALUES('schema_version', '6');
INSERT INTO rb_db_lov VALUES('data_timestamp', strftime('%s', 'now'));
