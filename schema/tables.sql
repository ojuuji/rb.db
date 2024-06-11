.bail ON

/*
  Original Rebrickable tables
*/

CREATE TABLE colors(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  -- rgb consists of six hex digits
  rgb TEXT NOT NULL CHECK(length(rgb) == 6 AND NOT rgb GLOB '*[^0-9A-Fa-f]*'),
  is_trans TEXT NOT NULL CHECK(is_trans IN ('f', 't'))
) STRICT;

CREATE TABLE themes(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id INTEGER REFERENCES themes(id)
) STRICT;

CREATE TABLE part_categories(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
) STRICT;

CREATE TABLE parts(
  -- part_num may also contain a dot ('14728c21.6') and a hyphen ('134916-740')
  part_num TEXT PRIMARY KEY CHECK(NOT part_num GLOB '*[^0-9A-Za-z.-]*'),
  name TEXT NOT NULL,
  part_cat_id INTEGER NOT NULL REFERENCES part_categories(id),
  part_material TEXT NOT NULL CHECK(part_material IN ('Cardboard/Paper', 'Cloth', 'Flexible Plastic', 'Foam', 'Metal', 'Plastic', 'Rubber'))
) STRICT;

CREATE TABLE part_relationships(
  rel_type TEXT NOT NULL CHECK(rel_type IN ('A', 'B', 'M', 'P', 'R', 'T')),
  child_part_num TEXT NOT NULL REFERENCES parts(part_num),
  parent_part_num TEXT NOT NULL REFERENCES parts(part_num)
) STRICT;

CREATE TABLE elements(
  element_id INTEGER PRIMARY KEY,
  part_num TEXT NOT NULL REFERENCES parts(part_num),
  color_id INTEGER NOT NULL REFERENCES colors(id),
  design_id INTEGER
) STRICT;

CREATE TABLE minifigs(
  fig_num TEXT PRIMARY KEY CHECK(NOT fig_num GLOB '*[^0-9A-Za-z-]*'),
  name TEXT NOT NULL,
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/sets/') == 1)
) STRICT;

CREATE TABLE sets(
  -- set_num may also contain a dot ('1224.1-1')
  set_num TEXT PRIMARY KEY CHECK(NOT set_num GLOB '*[^0-9A-Za-z.-]*'),
  name TEXT NOT NULL,
  year INTEGER NOT NULL CHECK(year >= 1932 AND year <= 1 + CAST(strftime('%Y', CURRENT_TIMESTAMP) AS INTEGER)),
  theme_id INTEGER NOT NULL REFERENCES themes(id),
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/sets/') == 1)
) STRICT;

CREATE TABLE inventories(
  id INTEGER PRIMARY KEY,
  version INTEGER NOT NULL CHECK(version >= 1),
  set_num TEXT NOT NULL REFERENCES set_nums(set_num)
) STRICT;

CREATE TABLE inventory_minifigs(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  fig_num TEXT NOT NULL REFERENCES minifigs(fig_num),
  quantity INTEGER NOT NULL
) STRICT;

CREATE TABLE inventory_parts(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  part_num TEXT NOT NULL REFERENCES parts(part_num),
  color_id INTEGER NOT NULL REFERENCES colors(id),
  quantity INTEGER NOT NULL,
  is_spare TEXT NOT NULL CHECK(is_spare IN ('f', 't')),
  img_url TEXT CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/parts/') == 1)
) STRICT;

CREATE TABLE inventory_sets(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  set_num TEXT NOT NULL REFERENCES sets(set_num),
  quantity INTEGER NOT NULL
) STRICT;

/*
  Technical table to satisfy inventories.set_num foreign key constraint
*/

CREATE TABLE set_nums(
  set_num TEXT PRIMARY KEY
) STRICT;

CREATE TRIGGER insert_set_num
  AFTER INSERT ON sets FOR EACH ROW
BEGIN
  INSERT INTO set_nums (set_num) VALUES (new.set_num);
END;

CREATE TRIGGER insert_fig_num
  AFTER INSERT ON minifigs FOR EACH ROW
BEGIN
  INSERT INTO set_nums (set_num) VALUES (new.fig_num);
END;

/*
  Custom tables
*/

CREATE TABLE color_properties(
  sort_pos INTEGER PRIMARY KEY,
  color_id INTEGER NOT NULL REFERENCES colors(id),
  delta_e REAL NOT NULL
) STRICT;

CREATE TABLE part_rels_resolved(
  rel_type TEXT NOT NULL CHECK(rel_type IN ('A', 'M')),
  child_part_num TEXT NOT NULL REFERENCES parts(part_num),
  parent_part_num TEXT NOT NULL REFERENCES parts(part_num)
) STRICT;
