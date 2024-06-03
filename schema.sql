.bail ON

DROP TABLE IF EXISTS colors;

CREATE TABLE colors(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  -- rgb consists of six hex digits
  rgb TEXT NOT NULL CHECK(length(rgb) == 6 AND NOT rgb GLOB '*[^0-9A-Fa-f]*'),
  is_trans TEXT NOT NULL CHECK(is_trans IN ('f', 't'))
) STRICT;

DROP TABLE IF EXISTS themes;

CREATE TABLE themes(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id INTEGER REFERENCES themes(id)
) STRICT;

DROP TABLE IF EXISTS part_categories;

CREATE TABLE part_categories(
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
) STRICT;

DROP TABLE IF EXISTS parts;

CREATE TABLE parts(
  -- part_num may also contain a dot ('14728c21.6') and a hyphen ('134916-740')
  part_num TEXT PRIMARY KEY CHECK(NOT part_num GLOB '*[^0-9A-Za-z.-]*'),
  name TEXT NOT NULL,
  part_cat_id INTEGER NOT NULL REFERENCES part_categories(id),
  part_material TEXT NOT NULL CHECK(part_material IN ('Cardboard/Paper', 'Cloth', 'Flexible Plastic', 'Foam', 'Metal', 'Plastic', 'Rubber'))
) STRICT;

DROP TABLE IF EXISTS part_relationships;

CREATE TABLE part_relationships(
  rel_type TEXT NOT NULL CHECK(rel_type IN ('A', 'B', 'M', 'P', 'R', 'T')),
  child_part_num TEXT NOT NULL REFERENCES parts(part_num),
  parent_part_num TEXT NOT NULL REFERENCES parts(part_num)
) STRICT;

DROP TABLE IF EXISTS elements;

CREATE TABLE elements(
  element_id INTEGER PRIMARY KEY,
  part_num TEXT NOT NULL REFERENCES parts(part_num),
  color_id INTEGER NOT NULL REFERENCES colors(id),
  design_id INTEGER
) STRICT;

DROP TABLE IF EXISTS minifigs;

CREATE TABLE minifigs(
  fig_num TEXT PRIMARY KEY CHECK(NOT fig_num GLOB '*[^0-9A-Za-z-]*'),
  name TEXT NOT NULL,
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/sets/') == 1)
) STRICT;

DROP TABLE IF EXISTS sets;

CREATE TABLE sets(
  -- set_num may also contain a dot ('1224.1-1')
  set_num TEXT PRIMARY KEY CHECK(NOT set_num GLOB '*[^0-9A-Za-z.-]*'),
  name TEXT NOT NULL,
  year INTEGER NOT NULL CHECK(year >= 1932 AND year <= 1 + CAST(strftime('%Y', CURRENT_TIMESTAMP) AS INTEGER)),
  theme_id INTEGER NOT NULL REFERENCES themes(id),
  num_parts INTEGER NOT NULL,
  img_url TEXT NOT NULL CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/sets/') == 1)
) STRICT;

DROP TABLE IF EXISTS inventories;

CREATE TABLE inventories(
  id INTEGER PRIMARY KEY,
  version INTEGER NOT NULL CHECK(version >= 1),
  set_num TEXT NOT NULL REFERENCES set_nums(set_num)
) STRICT;

DROP TABLE IF EXISTS inventory_minifigs;

CREATE TABLE inventory_minifigs(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  fig_num TEXT NOT NULL REFERENCES minifigs(fig_num),
  quantity INTEGER NOT NULL
) STRICT;

DROP TABLE IF EXISTS inventory_parts;

CREATE TABLE inventory_parts(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  part_num TEXT NOT NULL REFERENCES parts(part_num),
  color_id INTEGER NOT NULL REFERENCES colors(id),
  quantity INTEGER NOT NULL,
  is_spare TEXT NOT NULL CHECK(is_spare IN ('f', 't')),
  img_url TEXT CHECK(instr(img_url, 'https://cdn.rebrickable.com/media/parts/') == 1)
) STRICT;

DROP TABLE IF EXISTS inventory_sets;

CREATE TABLE inventory_sets(
  inventory_id INTEGER NOT NULL REFERENCES inventories(id),
  set_num TEXT NOT NULL REFERENCES sets(set_num),
  quantity INTEGER NOT NULL
) STRICT;

/*
  inventories.set_num may be either sets.set_num or minifigs.fig_num. We cannot
  reference them both as foreign key for inventories.set_num so they both are
  combined in set_nums table below and then set_nums.set_num is referenced as
  foreign key.
*/

DROP TABLE IF EXISTS set_nums;

CREATE TABLE set_nums(
  set_num TEXT PRIMARY KEY
) STRICT;

drop trigger IF EXISTS insert_set_num;

create trigger insert_set_num
  after insert on sets for each row
begin
  insert into set_nums (set_num) values (new.set_num);
end;

drop trigger IF EXISTS insert_fig_num;

create trigger insert_fig_num
  after insert on minifigs for each row
begin
  insert into set_nums (set_num) values (new.fig_num);
end;
