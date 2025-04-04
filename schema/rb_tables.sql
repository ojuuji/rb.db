.bail ON

/*
  Original Rebrickable tables
*/

CREATE TABLE colors(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  -- rgb consists of six hex digits
  rgb TEXT NOT NULL CHECK(length(rgb) == 6 AND NOT rgb GLOB '*[^0-9A-Fa-f]*'),
  is_trans INTEGER NOT NULL CHECK(is_trans IN (0, 1)),
  num_parts INTEGER NOT NULL,
  num_sets INTEGER NOT NULL,
  y1 INTEGER CHECK(y1 >= 1932 AND y1 <= 1 + CAST(strftime('%Y', CURRENT_TIMESTAMP) AS INTEGER)),
  y2 INTEGER CHECK(y2 >= 1932 AND y2 <= 1 + CAST(strftime('%Y', CURRENT_TIMESTAMP) AS INTEGER)),
  CHECK (y1 IS NULL AND y2 IS NULL OR y1 IS NOT NULL AND y2 IS NOT NULL AND y1 <= y2)
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
  fig_num TEXT PRIMARY KEY CHECK(fig_num GLOB 'fig-[0-9][0-9][0-9][0-9][0-9][0-9]'),
  name TEXT NOT NULL,
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL,
  CHECK(img_url = 'https://cdn.rebrickable.com/media/sets/' || fig_num || '.jpg')
) STRICT;

CREATE TABLE sets(
  -- set_num may also contain a dot ('1224.1-1')
  set_num TEXT PRIMARY KEY CHECK(set_num NOT GLOB '*[^0-9A-Za-z.-]*' AND set_num NOT LIKE 'fig-%'),
  name TEXT NOT NULL,
  year INTEGER NOT NULL CHECK(year >= 1932 AND year <= 1 + CAST(strftime('%Y', CURRENT_TIMESTAMP) AS INTEGER)),
  theme_id INTEGER NOT NULL REFERENCES themes(id),
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL,
  CHECK(img_url = 'https://cdn.rebrickable.com/media/sets/' || lower(set_num) || '.jpg')
) STRICT;

CREATE TABLE inventories(
  id INTEGER PRIMARY KEY,
  version INTEGER NOT NULL CHECK(version >= 1),
  set_num TEXT NOT NULL REFERENCES set_nums(set_num),
  CHECK (version = 1 OR set_num NOT LIKE 'fig-%')
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
  is_spare INTEGER NOT NULL CHECK(is_spare IN (0, 1)),
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
