
- [Database Schema](#database-schema)
  - [Changelog](#changelog)
  - [Diagram](#diagram)
- [Rebrickable Tables](#rebrickable-tables)
  - [colors](#colors)
  - [themes](#themes)
  - [part_categories](#part_categories)
  - [parts](#parts)
  - [part_relationships](#part_relationships)
    - [`A` - Alternate](#a---alternate)
    - [`B` - Sub-Part](#b---sub-part)
    - [`M` - Mold](#m---mold)
    - [`P` - Print](#p---print)
    - [`R` - Pair](#r---pair)
    - [`T` - Pattern](#t---pattern)
  - [elements](#elements)
  - [minifigs](#minifigs)
  - [sets](#sets)
  - [inventories](#inventories)
  - [inventory_minifigs](#inventory_minifigs)
  - [inventory_parts](#inventory_parts)
  - [inventory_sets](#inventory_sets)
  - [set_nums](#set_nums)
- [Custom Tables](#custom-tables)
  - [color_properties](#color_properties)
  - [similar_colors](#similar_colors)
  - [part_rels_resolved](#part_rels_resolved)
  - [part_rels_extra](#part_rels_extra)
  - [Stats Tables](#stats-tables)
  - [part_color_stats](#part_color_stats)
  - [part_stats](#part_stats)
  - [color_stats](#color_stats)
  - [rb_db_lov](#rb_db_lov)
- [Examples](#examples)

{% include download.html %}

The main goal of `rb.db` is to provide original, unmodified tables from [Rebrickable Downloads](https://rebrickable.com/downloads/) in a form of ready-to-use SQLite database file, and build it on schedule, so the latest release provides always up-to-date version of the database.

Releases are created automatically once a day, but only if there were actual changes since the last release.

Retention policy:

- git tag [`latest`]({{ site.github.repository_url }}/releases/tag/latest) is always recreated when releasing new version, so the [latest version]({{ site.github.releases_url }}/download/latest/rb.db.xz) link is permanent
- git tag `latest-v<N>`, where `<N>` is the latest schema version, is also always recreated, and similar tags for older schemas are retained. The rationale is described in [`schema_version`](#schema_version) section
- the last 10 releases are retained unconditionally
- for older releases is retained the latest release of the month

# Database Schema

For Rebrickable tables the main rule is to import them as-is, without adding/removing/modifying any table/column names or data except for the purpose of data types conversion, as described further in this topic. Schema also enforces several constraints to ensure the database integrity and the relevance of this documentation:

- foreign key constraints for all columns which reference other tables
- value constraints (from `NOT NULL` to more specific whenever possible)
- [`set_nums`](#set_nums) table to satisfy foreign key constraint for [`inventories.set_num`](#inventories)
- rigid typing via SQLite [STRICT tables](https://www.sqlite.org/stricttables.html)

CSV format, in which original Rebrickable tables are provided, cannot include types information for the stored data. Therefore column data types, used by the schema, are determined basing on the column content and SQLite3 specifics:

- use only `INTEGER` and `TEXT` to avoid possible confusion, as the data types like `VARCHAR(N)` do not really imply any constraints in SQLite ([docs](https://www.sqlite.org/datatype3.html)). Rigid typing allows only a few data types, so this was (fortunately) not much of a choice
- use `INTEGER` values `0` and `1` for boolean columns. Original tables store words `True`/`False` (or, before 14-Nov-2024, single `t`/`f` characters), but in context of the schema `0`/`1` are more appropriate as they allow to use natural conditions like `WHERE is_trans`/`WHERE NOT is_trans`
- use `INTEGER` for columns containing id, year, quantity. The rest of columns are clearly text so it was not a hard guess
- CSV has no concept of `NULL` values whereas all missing values in the Rebrickable tables semantically mean `NULL` and thus are imported this way in `rb.db`

Schema of the Rebrickable tables is described in [Rebrickable Tables](#rebrickable-tables) section. `rb.db` also includes few custom tables, non-trivially generated from them, and some handy views. They are described in [Custom Tables](#custom-tables) section.

Almost all columns in the tables cannot be `NULL`. Thus this is not mentioned in the columns description, and only for nullable columns there will be explicit note about this.

### Note about CSV import in SQLite3

Original Rebrickable tables are provided in CSV format. SQLite [can import](https://sqlite.org/cli.html#importing_files_as_csv_or_other_formats) tables from CSV files directly. However it unconditionally treats empty values as empty strings ([details](https://sqlite.org/forum/forumpost/9da85fe4fc6760c4)) whereas in context of Rebrickable tables these values have to become `NULL` in database.

For example, [`themes.parent_id`](#themes) foreign key constraint would fail at all with an empty string, because it expects either an existing `themes.id` value or `NULL`.

This is why the import scripts import tables directly instead of relying on `.import` SQLite3 command.

## Changelog

Current [schema version](#rb_db_lov) is **8**.

Last modified on 16-Feb-2025 due to a change in Rebrickable tables: four new columns (`num_parts`, `num_sets`, `y1`, `y2`) were added to the [`colors`](#colors) table.

<details>

<summary>Older changes</summary>

<p>v7: [22-Jun-2024] added view <code><a href="#color_stats">color_stats</a></code> and merged views <code>part_[color_]images</code> with <code>part_[color_]stats</code>.</p>

<p>v6: added views <code><a href="#part_color_stats">part_color_stats</a></code>, <code><a href="#part_stats">part_stats</a></code>, <code><a href="#part_color_images">part_color_images</a></code>, <code><a href="#part_images">part_images</a></code>.</p>

<p>v5: added column <code><a href="#color_properties">color_properties.is_grayscale</a></code>.</p>

<p>v4: changed column types to <code>integer (0/1)</code> for <code><a href="#colors">colors.is_trans</a></code> and <code><a href="#inventory_parts">inventory_parts.is_spare</a></code>.</p>

<p>v3: added table <code><a href="#part_rels_extra">part_rels_extra</a></code>.</p>

<p>v2: renamed column <code>color_properties.color_id</code> to <code><a href="#color_properties">color_properties.id</a></code> as this is complementary table.</p>

<p>v1: added table <code><a href="#rb_db_lov">rb_db_lov</a></code>.</p>

</details>

## Diagram

![Database diagram](schema.svg)

# Rebrickable Tables

## colors

This table contains the [part colors](https://rebrickable.com/colors/).

Columns: `id` (integer, primary key), `name` (text), `rgb` (text), `is_trans` (integer), `num_parts` (integer), `num_sets` (integer), `y1` (integer, nullable), `y2` (integer, nullable).

`id` is a number, unique for each color. Referenced by [`inventory_parts.color_id`](#inventory_parts), [`elements.color_id`](#elements), [`color_properties.id`](#color_properties), [`similar_color_ids.ref_id`](#similar_colors), [`similar_color_ids.id`](#similar_colors).

`name` is the color name on Rebrickable.

`rgb` is RGB color in a form of [HEX triplet](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), 6 hexadecimal digits without prefix.

`is_trans` is a `0`/`1` flag indicating if color is transparent.

`num_sets` is a number of sets containing parts in this color. This is "Num Sets" column on the [part colors](https://rebrickable.com/colors/) page. As for now it seems to have duplicate sets (one set per each unique combination of part and color, not just per color), see [output](examples/color_stats_diff.txt) of the "Stats difference in `colors` table" [example](#examples).

`min_year` is the year of the set where this color was first used for the parts. This is "First Year" column on the [part colors](https://rebrickable.com/colors/) page.

`max_year` is the year of the set where parts in this color were last seen. This is "Last Year" column on the [part colors](https://rebrickable.com/colors/) page.

`num_parts` is total number of these parts in this color across all sets. This is "Num Parts" column on the [part colors](https://rebrickable.com/colors/) page.

As for the last four columns, from database architecture point of view it might be strange to have stats in fundamental `colors` table. (sigh) Well, it helps to think that the original CSV tables aim to be convenient for the users in the first place, not to keep some purity of the database schema.

In case you have "ambiguous column name" errors when joining colors table because of these stats fields, as an option to keep surrounding query unchanged, you can use subquery `(SELECT id, name, rgb, is_trans FROM colors)` in place of `colors` table. Or, depending on the context, a shorter list of columns, for example, `JOIN colors c` → `JOIN (SELECT id, name FROM colors) c`.

You may also take a look at [`color_stats`](#color_stats) table, which contains the same stats, but derived from other tables. In case you need similar stats for parts, take a look at [`part_color_stats`](#part_color_stats) and [`part_stats`](#part_stats).

Example:

```sh
$ sqlite3 -header -column rb.db "select is_trans, count(*) from colors group by is_trans union select 'total', count(*) from colors"
is_trans  count(*)
--------  -----
0         222
1         45
total     267
```

## themes

This table contains the [set themes](https://rebrickable.com/help/set-themes/).

Columns: `id` (integer, primary key), `name` (text), `parent_id` (integer, nullable).

`id` is a number, unique for each theme. Referenced by [`sets.theme_id`](#sets) and even by this table in `parent_id` column.

`name` is the theme name on Rebrickable.

`parent_id` is the parent theme id for sub-themes and `NULL` otherwise.

As for now, the maximum length of themes chain is **3** (A→B→C).

Example:

```sh
$ sqlite3 -table -nullvalue NULL rb.db "select * from themes where 52 in (id, parent_id) limit 2"
+----+---------+-----------+
| id |  name   | parent_id |
+----+---------+-----------+
| 52 | City    | NULL      |
| 53 | Airport | 52        |
+----+---------+-----------+
```

## part_categories

Columns: `id` (integer, primary key), `name` (text).

`id` is a number, unique for each category. Referenced by [`parts.part_cat_id`](#parts).

`name` is the part category name on Rebrickable. It is used, for example, in `Category` dropdown on the [Parts](https://rebrickable.com/parts/) page.

## parts

Columns: `part_num` (text, primary key), `name` (text), `part_cat_id` (integer), `part_material` (text).

`part_num` is alpha-numeric part number uniquely identifying each part on Rebrickable. Referenced by [`part_relationships.child_part_num`](#part_relationships), [`part_relationships.parent_part_num`](#part_relationships), [`elements.part_num`](#elements), [`inventory_parts.part_num`](#inventory_parts), [`part_rels_resolved.child_part_num`](#part_relationships), [`part_rels_resolved.parent_part_num`](#part_relationships).

Although uncommon, part numbers may also contain a dot ([`75c23.75`](https://rebrickable.com/parts/75c23.75/)) and a hyphen ([`134916-740`](https://rebrickable.com/parts/134916-740/)).

`name` is the part name on Rebrickable.

`part_cat_id` is a reference (foreign key) to [`part_categories.id`](#part_categories) column.

`part_material` is the material from which this part is made. Possible values:

```sh
$ sqlite3 rb.db "select distinct(part_material) from parts"
Cardboard/Paper
Cloth
Flexible Plastic
Foam
Metal
Plastic
Rubber
```

## part_relationships

Columns: `rel_type` (text), `child_part_num` (text), `parent_part_num` (text).

Each row defines single relationship between two parts `child_part_num` and `parent_part_num`, which both are references (foreign keys) to [`parts.part_num`](#parts) column.

`rel_type` is a relationship type, defined by a single character, one of `A`, `B`, `M`, `P`, `R`, `T`. They all are described in the following sections.

Neither `rel_type+child_part_num` nor `rel_type+parent_part_num` are unique across the table.

### `A` - Alternate

Example: `A,11954,62531`

For [`11954`](https://rebrickable.com/parts/11954/) Rebrickable will say it is usable as alternate for the [`62531`](https://rebrickable.com/parts/62531/). And vice versa.

Rebrickable uses this relationship in the build matching option _"Consider alternate parts that can usually be used as replacements, but are not always functionally compatible."_

There will be no corresponding row `A,62531,11954` so this relationship should be considered bidirectional.

### `B` - Sub-Part

Example: `B,6051,6051c04`

[`6051`](https://rebrickable.com/parts/6051/) is a sub-part of [`6051c04`](https://rebrickable.com/parts/6051c04/).

### `M` - Mold

Example: `M,92950,3455`

[`92950`](https://rebrickable.com/parts/92950/) and [`3455`](https://rebrickable.com/parts/3455/) are essentially the same parts where 92950 is a newer mold. For 3455 Rebrickable says it is superseded by 92950.

Rebrickable uses this relationship in the build matching option _"Ignore mold variations in parts."_

The successor part is not necessarily listed as `child_part_num`. And an older part is not necessarily listed as `parent_part_num`. Here are two examples in the form `child_part_num (year_from, year_to) -> parent_part_num (year_from, year_to)`:

```text
60608 (2007, <present>) -> 3854 (1978, 2008)
3002a (1954, 1990) -> 3002 (1979, <present>)
```

In case of multiple molds not all combinations are listed. For example, for parts [`67695`](https://rebrickable.com/parts/67695/), [`93571`](https://rebrickable.com/parts/93571/), [`32174`](https://rebrickable.com/parts/32174/) there are two rows:

```csv
M,93571,32174
M,67695,32174
```

But there are no row `M,93571,67695` (for the info, `67695` is the latest mold).

Also, alternates not necessarily point to the latest molds, and they may have molds too (as mentioned above, 32174 is an older mold of 67695):

```csv
A,60176,32174
M,89652,60176
```

With that said, it is not easy to get the most relevant mold for a given part number using this table. As an alternative, you may try [`part_rels_resolved`](#part_rels_resolved) table.

### `P` - Print

Example: `P,4740pr0014,4740`

[`4740pr0014`](https://rebrickable.com/parts/4740pr0014/) is a print of [`4740`](https://rebrickable.com/parts/4740/).

Rebrickable uses this relationship along with relationship `T` in the build matching option _"Ignore printed and patterned part differences."_

### `R` - Pair

Example: `R,18947,35188`

[`18947`](https://rebrickable.com/parts/18947/) pairs with [`35188`](https://rebrickable.com/parts/35188/). And vice versa.

There will be no corresponding row `R,35188,18947` so this relationship should be considered bidirectional.

### `T` - Pattern

Example: `T,19858pat0002,19858`

[`19858pat0002`](https://rebrickable.com/parts/19858pat0002/) is a pattern of [`19858`](https://rebrickable.com/parts/19858/).

Rebrickable uses this relationship along with relationship `P` in the build matching option _"Ignore printed and patterned part differences."_

## elements

Columns: `element_id` (integer, primary key), `part_num` (text), `color_id` (integer), `design_id` (integer, nullable).

`element_id` is the most unique characteristic of a part.

The same sets of `part_num`+`color_id`+`design_id` may have multiple `element_id`:

```sh
$ sqlite3 -table rb.db "select * from elements where part_num = '75c06'"
+------------+----------+----------+-----------+
| element_id | part_num | color_id | design_id |
+------------+----------+----------+-----------+
| 4118741    | 75c06    | 0        | 76279     |
| 4270745    | 75c06    | 0        | 76279     |
| 4495367    | 75c06    | 0        | 76279     |
| 4505063    | 75c06    | 0        |           |
| 4546459    | 75c06    | 0        | 76279     |
| 4640742    | 75c06    | 0        | 76279     |
| 6439553    | 75c06    | 10       |           |
| 6451143    | 75c06    | 10       | 100754    |
| 4226277    | 75c06    | 134      |           |
| 4268282    | 75c06    | 134      |           |
| 4285897    | 75c06    | 134      |           |
+------------+----------+----------+-----------+
```

For most of the part image URLs Rebrickable uses `element_id` (URL ends then with `/parts/elements/<element_id>.jpg`). However, not every element has an image. Also some parts do not have element images at all and instead use LDraw images or photos. So `element_id` is not reliable way to get the part image URL for a given `part_num`+`color_id`. See [`inventory_parts.img_url`](#inventory_parts) for a better solution.

This table is not referenced by other tables in the schema.

## minifigs

This table lists [minifigs](https://rebrickable.com/help/minifigs-standards/). Unlike it may seem, minifig is not necessarily a derivative of torso+legs. Some minifigs are made of regular parts, for example, [fig-014490](https://rebrickable.com/minifigs/fig-014490/).

Columns: `fig_num` (text, primary key), `name` (text), `num_parts` (integer), `img_url` (text).

`fig_num` is an id unique for each minifig. Referenced by [`inventory_minifigs.fig_num`](#inventory_minifigs), and by [`inventories.set_num`](#inventories) trough [`set_nums`](#set_nums) table.

All `fig_num` values follow this format: `fig-NNNNNN`, i.e. 6 decimal digits prefixed with "fig-". This is an internal id, assigned and used exclusively by Rebrickable.

`name` is the minifig name on Rebrickable.

`num_parts` is the number of parts in the minifig inventory. For the info, some minifigs have 100+ parts, for example, 141 in [fig-014675](https://rebrickable.com/minifigs/fig-014675/).

`img_url` is the minifig image URL. As for now, _every_ `img_url` follows this format: `https://cdn.rebrickable.com/media/sets/<fig_num>.jpg`. So, for example, when embedding a subset of the database, `img_url` can be omitted to reduce data size.

## sets

Columns: `set_num` (text, primary key), `name` (text), `year` (integer), `theme_id` (integer), `num_parts` (integer), `img_url` (text).

`set_num` is an id unique for each set. Referenced by [`inventory_sets.set_num`](#inventory_sets), and by [`inventories.set_num`](#inventories) trough [`set_nums`](#set_nums) table.

`name` is the set name on Rebrickable.

`year` is the year when the set was released. Fairly important column, as the usage years for the parts and colors are made using it. For example, a year, from which the part is used, is calculated as the year of a set where this part was used first. So, basically, if part+color combination is not available in any sets then it "does not exist". Because of this Rebrickable uses [Database Sets](https://rebrickable.com/sets/?theme=746) to avoid errors for parts which were not (yet) released within regular sets.

`theme_id` is the set theme as a reference (foreign key) to [`themes.id`](#themes) column.

`num_parts` is total number of parts in the set, including parts from minifigs if it has any, but not including spare parts. For example, set [60428-1](https://rebrickable.com/sets/60428-1/) has 114 standard parts, two minifigs with 6 and 20 parts, and 8 spare parts. `num_parts` is `140=114+6+20`.

If the set includes other sets, for example [K4515-1](https://rebrickable.com/sets/K4515-1/), then parts from them are not counted in `num_parts` of the main set.

`img_url` is the image URL of the set. As for now, _every_ `img_url` follows this format: `https://cdn.rebrickable.com/media/sets/<set_num_LOWERCASE>.jpg` (note, `set_num` must be in lowercase otherwise URL results in HTTP 404). So, for example, when embedding a subset of the database, `img_url` can be omitted to reduce data size.

## inventories

Columns: `id` (integer, primary key), `version` (integer), `set_num` (text).

`id` is a number, unique for each inventory. Referenced by [`inventory_minifigs.inventory_id`](#inventory_minifigs), [`inventory_parts.inventory_id`](#inventory_parts), [`inventory_sets.inventory_id`](#inventory_sets).

Being referenced by these three tables means inventory may include standard parts, minifigs, and even other sets.

`version` is the inventory version on Rebrickable. Although in most cases version starts from 1, this is not mandatory (e.g. in [10875-1](https://rebrickable.com/sets/10875-1/#parts) it start from 2). Also versions can be non-sequential (e.g. [21011-1](https://rebrickable.com/sets/21011-1/#parts) has only versions 1 and 3).

`set_num` references either [`minifigs.fig_num`](#minifigs) or [`sets.set_num`](#sets). So this table contains inventories for both sets and minifigs.

As for now, `minifigs` do not have multiple inventories, i.e. for minifig inventories `version` is always equal to `1`.

On practice minifig inventories include only standard parts, i.e. they link only to `inventory_parts` table. As for the sets, they may include all three types of content (i.e. parts, minifigs, sets), for example, [`COMCON002-1`](https://rebrickable.com/sets/COMCON002-1/). Nevertheless Rebrickable counts only standard parts and parts from minifigs in combined inventory of the main set. So does `rb.db` in [`part_stats.num_parts`](#part_stats) and elsewhere.

## inventory_minifigs

Columns: `inventory_id` (integer), `fig_num` (text), `quantity` (integer).

`inventory_id` is a reference (foreign key) to [`inventories.id`](#inventories) column.

It represents inventory, which includes this minifig, **not** the inventory of minifig itself. To get inventory of minifig use `SELECT id from inventories WHERE set_num = '<fig_num_you_need>'`.

`fig_num` is a reference (foreign key) to [`minifigs.fig_num`](#minifigs).

`quantity` is a number of these minifigs in the inventory.

## inventory_parts

Columns: `inventory_id` (integer), `part_num` (text), `color_id` (integer), `quantity` (integer), `is_spare` (integer), `img_url` (text, nullable).

`inventory_id` is a reference (foreign key) to [`inventories.id`](#inventories) column.

`part_num` is a reference (foreign key) to [`parts.part_num`](#parts) column.

`color_id` is a reference (foreign key) to [`colors.id`](#colors) column.

`quantity` is a number of combinations `part_num`+`color_id`+`is_spare` in this inventory. Note that for spare parts there will be separate rows in inventory.

`is_spare` is a `0`/`1` flag indicating if this is a spare part. Currently minifig inventories never have spare parts. Only the set inventories may have spare parts, including spare parts for minifigs from these sets. Thus, a situation is possible when the set inventory contains spare part that is unique to this inventory (i.e. it is only used in minifig which has its own inventory).

`img_url` is the part image URL. When not `NULL` it always starts with `'https://cdn.rebrickable.com/media/parts/'`.

As for now, this `img_url` is the most reliable way to get an image URL for a given `part_num`+`color_id`, so `img_url` in [`part_color_stats`](#part_color_stats) and [`part_stats`](#part_stats) is based on it.

However note that if part does not have image, Rebrickable uses part images in other colors or, if there are none, it may use images of similar parts (e.g. molds or plain parts for prints). There are no way to know in Rebrickable tables if image is canonical, or it is from other part color, or from a similar part.

On Rebrickable similar part images in inventories are marked with ["Similar Image"](https://rebrickable.com/static/img/overlays/similar.png) overlay and a note in image title saying _"Exact image not available, using similar image from part `<similar_part_num>`"_. Part images in other colors are not marked.

For [almost](examples/diff_img_in_same_part.txt) all parts their image URLs are the same across all inventories.

## inventory_sets

Columns: `inventory_id` (integer), `set_num` (text), `quantity` (integer).

`inventory_id` is a reference (foreign key) to [`inventories.id`](#inventories) column.

It represents inventory, which includes this set, **not** the inventory of the set itself. To get inventory of the set use `SELECT id from inventories WHERE set_num = '<set_num_you_need>'`.

`set_num` is a reference (foreign key) to [`sets.set_num`](#sets).

`quantity` is a number of these sets in the inventory.

## set_nums

Columns: `set_num` (text, primary key).

This is "technical" table whose sole purpose is to satisfy foreign key constraint for [`inventories.set_num`](#inventories) column.

`inventories.set_num` column may contain either `sets.set_num` or `minifigs.fig_num` but foreign key cannot reference two columns. So both these columns are combined in `set_nums` table using triggers and `inventories.set_num` references only `set_nums.set_num`.

This table is included in the database even when building Rebrickable tables alone, without [custom tables](#custom-tables), using `build.sh -rbonly` from the [source repository]({{ site.github.repository_url }}).

It would be hard to decide if this table should be part of Rebrickable tables, or it should be implemented in custom tables via `ADD CONSTRAINT` variant of the `ALTER TABLE`. Fortunately SQLite leaves no choice here by [not supporting](https://www.sqlite.org/omitted.html) this variant of `ALTER TABLE`.

# Custom Tables

These tables are non-trivially generated, i.e. their data cannot be obtained using, for example, some simple query statement.

## color_properties

This is complementary 1-to-1 table to [`colors`](#colors) table and is separated only because Rebrickable tables are never modified in `rb.db`.

Columns: `id` (integer, primary key), `sort_pos` (integer), `is_grayscale` (integer, nullable).

`id` is a reference (foreign key) to [`colors.id`](#colors) column.

`sort_pos` is a color position in a sorted list of colors. It is designed to help sorting parts by color.

`is_grayscale` is a `0`/`1` flag indicating if color is considered as grayscale. In the following list it is set to `1` for points #3, #4, #5, to `0` for point #6, and to `NULL` for points #1, #2.

With the `sort_pos` colors are ordered the following way:

1. `[Unknown]`
2. `[No Color/Any Color]`
3. `White`
4. `Black`
5. Grayscale colors from darker to lighter
6. Remaining colors, ordered by [hue](https://en.wikipedia.org/wiki/Hue)

It is based on the colors order used in _"Your Colors"_ section on the part pages on Rebrickable.

Example:

```sh
$ sqlite3 -csv rb.db "select id, name from colors natural join color_properties order by sort_pos limit 10"
-1,[Unknown]
9999,"[No Color/Any Color]"
15,White
0,Black
1103,"Pearl Titanium"
1018,"Modulex Black"
148,"Pearl Dark Gray"
1016,"Modulex Charcoal Gray"
1040,"Modulex Foil Dark Gray"
1126,"HO Metallic Dark Gray"
```

## similar_colors

Columns: `ref_id` (integer, primary key), `ref_name` (text), `id` (integer), `name` (text), `rgb` (text), `is_trans` (integer).

This table lists similar colors for every color. It is inspired by Rebrickable build matching option _"Part color sensitivity" → "Parts that have similar colors will be matched."_ though results may be different.

`ref_id` and `id` are references (foreign keys) to [`colors.id`](#colors) column. Technically `similar_colors` is a view to `similar_color_ids`, which contains just these two columns and joined `colors` table on both of them.

Column `ref_id` is indexed, so it is better to search by it instead of `id`. For every pair of similar colors `X→Y` table also contains pair `Y→X` so it is really enough to search only by `ref_id` or `ref_name`.

Additional rules apply:

- `[Unknown]` color is never similar to any color
- `[No Color/Any Color]` color is similar to all colors
- any other color is similar also to itself i.e. there will be row where `ref_id = id`

Whether two colors are similar is determined using Delta E metric. [Here is great reading](https://zschuessler.github.io/DeltaE/learn/) about it. Specifically is used _"dE00"_ algorithm and the maximum Delta E value `20`. For those curious, [Delta E chart for Rebrickable colors](delta_e_chart.html).

Example:

```sh
$ sqlite3 rb.db "select name from similar_colors where ref_name = 'Red'"
Red
Trans-Red
Light Brown
Rust
Dark Red
Dark Orange
Vintage Red
Modulex Red
Modulex Pink Red
Modulex Foil Red
Dark Nougat
Bright Reddish Orange
Pearl Red
Rust Orange
Two-tone Copper
Two-tone Gold
Metallic Copper
Trans-Neon Red
HO Light Brown
HO Medium Red
HO Rose
Reddish Orange
Sienna Brown
[No Color/Any Color]
```

## part_rels_resolved

Columns: `rel_type` (text), `child_part_num` (text), `parent_part_num` (text).

This is a processed [`part_relationships`](#part_relationships) table with the same set of columns (see columns description there).

As a result of processing it lists so-called _"resolved"_ relationships, which are calculated this way:

- retain ony relationships [`A`](#a---alternate) and [`M`](#m---mold), as only these are subject of resolving (i.e. other rows would be the same as in `part_relationships`)
- in case of molds resolve them the following way (read related details in [`M` - Mold](#m---mold) section):
  - always list the successor part as `parent_part_num`
  - use the final successor part for all molds, i.e. if there are molds A→B and A→C, and the final successor is C, table will have A→C and B→C
  - as a successor use the part, which is referenced in a newer set, or, if the newest sets have the same year, is referenced in an older set, or, if the oldest sets also have the same year, is referenced in more sets
- in case of alternates:
  - first resolve molds for both `child_part_num` and `parent_part_num`
  - as `parent_part_num` use the part, which is referenced in a newer set, or, if the newest sets have the same year, the part that is referenced in more sets.

This way to resolve any `A`/`M` relationship it is enough to perform single lookup in this table. I.e. for any relationship `X` and part `Y` there will be either zero or one row `X,Y,Z` and no rows starting with `X,Z,` where `X` is either `A` or `M`.

## part_rels_extra

Columns: `rel_type` (text), `child_part_num` (text), `parent_part_num` (text).

This table defines extra relationships, not available on Rebrickable and maintained within `rb.db`.

Rebrickable does not use fictive parts as "common denominators" for other parts. For example, [`35074pr0003`](https://rebrickable.com/parts/35074pr0003/) and [`35074pr0009`](https://rebrickable.com/parts/35074pr0009/) are clearly prints of the same part but unprinted part `35074` does not exist and thus is not listed in Rebrickable tables.

In fact such parts actually exist on Rebrickable to some extent. For example, although [`35074`](https://rebrickable.com/parts/35074/) results in _"404 Page Not Found"_, this part is listed as print of [`35074pr0003`](https://rebrickable.com/parts/35074pr0003/) with _"INACTIVE"_ word, appended to its title, and with a note that _"This part is disabled and cannot be used."_.

There are exceptions though. For example, part [`973c00`](https://rebrickable.com/parts/973c00/) does not seem to really exist nevertheless its details page is available on the site.

So basically `part_rels_extra` table contains relationships, made using "common denominator" parts described above, and several extra alternates.

Content of this table is generated using the rules defined in [`part_rels_extra_rules.txt`]({{ site.github.repository_url }}/blob/master/build/part_rels_extra_rules.txt). See description in this file for details.

Relationships involving "common denominator" parts there can be summarized the following way:

- for every print there will be non-printed part. For example, part [`35074pr0003`](https://rebrickable.com/parts/35074pr0003/) results in a row `P,35074pr0003,35074` even if part `35074` does not exist
- the same is done for patterns but _after_ prints are removed. For example, for part [`100662pat0001pr0002`](https://rebrickable.com/parts/100662pat0001pr0002/) there will be rows `P,100662pat0001pr0002,100662pat0001` and `T,100662pat0001,100662` but not `P,100662pat0001pr0002,100662pr0002`. Also note that in the pattern row both parts do not actually exist
- minifig torsos and legs, after prints and patterns are removed, are additionally listed as alternates to `973c00` and `970c00` when reasonable.

When building this table, relationship is not added if it already exists in [`part_rels_resolved`](#part_rels_resolved) (for `rel_type` values `A`, `M`) or in [`part_relationships`](#part_relationships) (for the rest of `rel_type` values).

So `part_rels_extra` table complements both these tables. In other words, this union does not have duplicate rows:

```sql
SELECT *
  FROM part_relationships
 WHERE rel_type NOT IN ('A', 'M')
 UNION ALL
SELECT *
  FROM part_rels_resolved
 WHERE rel_type IN ('A', 'M')
 UNION ALL
SELECT *
  FROM part_rels_extra
```

## Stats Tables

The following three sections describe `part_color_stats`, `part_stats`, and `color_stats` tables. This section covers general considerations for all these tables.

When calculating number of the set parts, Rebrickable includes parts from the set inventory, parts from the set minifigs, and does not include spare parts. For example, [60063-1](https://rebrickable.com/sets/60063-1/) states there are 218 parts in total. Inventory lists 189 parts and 7 minifigs. Remaining 29 parts (218-189=29) belong to these 7 minifigs. 27 spare parts are not counted.

In case of [super sets](https://rebrickable.com/help/sets-types/) inventories from the included sets are not considered. For example, [K10194-1](https://rebrickable.com/sets/K10194-1/), which has 8 sets, has 0 parts in total.

The same considerations are used for `num_sets` and `num_parts` columns in the stats tables:

- super sets never affect both these columns
- when calculating number of sets, minifig parts are treated as parts of the set. I.e. no matter if part/color combination is included in one or more of the set minifigs and/or in the set inventory, `num_sets` for this part/color is always incremented by one
- when calculating number of parts, stats tables use "flattened" set inventory. This is a union of the set inventory parts and all inventory parts of the set minifigs, and does not include spare parts. I.e. the same that Rebrickable does when calculating total number of the set parts, as described in the example above.

It is also worth mentioning the sets with multiple inventory versions. On Rebrickable it is not like only the latest version is valid. All versions are valid. Yet difference may be very subtle. For example, in [42114-1](https://rebrickable.com/sets/42114-1/) inventories v1 and v2 [differ in only one part](https://rebrickable.com/sets/compare/slow/?1-set=42114-1&2-set=42114-1&1-inv=67064&2-inv=122878) out of 2193 parts.

In this case, for the stats purpose, `rb.db` takes the following approach. Additional inventory versions do not increase number of sets. And in calculating number of parts is used union of flattened set inventories from all inventory versions with duplicates removed. If different versions of flattened inventories have different number of parts for particular part/color combination, the larger one is used.

About the year in the stats. On Rebrickable particular combination of a part and color is considered to really exist only if it is included in the sets. And then the years of the sets is what actually defines part years on Rebrickable. The same is done in the stats tables here.

By the way, since particular combination of the part and color only goes "live" when it is included in a set, for parts, which are known to exist, but are not included in any real world sets, Rebrickable uses [Database Sets](https://rebrickable.com/sets/?theme=746&include_accessory=on).

## part_color_stats

Columns: `part_num` (text), `color_id` (integer), `num_sets` (integer), `min_year` (integer), `max_year` (integer), `num_parts` (integer), `img_url` (text, nullable).

This view contains statistics for all really existing combinations of the parts and colors. Read [Stats Tables](#stats-tables) for general considerations.

`part_num` is a reference (foreign key) to [`parts.part_num`](#parts) column.

`color_id` is a reference (foreign key) to [`colors.id`](#colors) column.

Together `part_num` and `color_id` represent combination of the part and color for which this row provides statistics.

`num_sets` is a number of sets containing this part in this color. Corresponding stat on Rebrickable is "Sets" column in "Available Colors" group on the part detail pages.

`min_year` is the year of the set where this part in this color was first introduced. Corresponding stat on Rebrickable is "From" column in "Available Colors" group on the part detail pages.

`max_year` is the year of the set where this part in this color was last seen. Corresponding stat on Rebrickable is "To" column in "Available Colors" group on the part detail pages.

`num_parts` is total number of these parts in this color across all sets. Corresponding stat on Rebrickable is "Set Parts" column in "Available Colors" group on the part detail pages.

`img_url` is an image URL for the part/color. It is based on [`inventory_parts`](#inventory_parts) table (read notes about `img_url` there). `part_color_stats` has only one row per part/color, so when choosing which image to use it follows this priority: `element` → `ldraw` → `photo` → `NULL` (but there are actually almost no parts with multiple image URLs).

## part_stats

Columns: `part_num` (text), `num_sets` (integer), `min_year` (integer), `max_year` (integer), `num_parts` (integer), `img_url` (text, nullable).

This view contains statistics for all really existing parts. Read [Stats Tables](#stats-tables) for general considerations.

It is similar to `part_color_stats`, but the stats for all part colors are combined together. Note, it is not a derivative of `part_color_stats`, as you cannot calculate, for example, `part_stats.num_sets` using `part_color_stats.num_sets`.

`part_num` is a reference (foreign key) to [`parts.part_num`](#parts) column.

`num_sets` is a number of sets containing this part. Corresponding stat on Rebrickable is "Num Sets" on the part detail pages.

`min_year` and `max_year` are the years of the sets where this part was first introduced and last seen, respectively. Corresponding stat on Rebrickable is "Year" on the part detail pages in form "`<min_year>` to `<max_year>`".

`num_parts` is total number of these parts across all sets. Corresponding stat on Rebrickable is "Num Set Parts" on the part detail pages.

`img_url` is an image URL for the part. When selecting image URL for the part in general, not for the part in specific color, Rebrickable chooses the part, which has the largest number of the set parts, even if it is referenced not in the most sets. The same is done here for `img_url`. Also read how `img_url` for particular part_num/color combination is selected in [`part_color_stats`](#part_color_stats) description.

## color_stats

Columns: `color_id` (integer), `num_sets` (integer), `min_year` (integer), `max_year` (integer), `num_parts` (integer).

This view contains statistics for all colors used in really existing parts. Read [Stats Tables](#stats-tables) for general considerations.

`num_sets` is a number of sets containing parts in this color. There is no corresponding stat on Rebrickable, as the "Num Sets" column on the [part colors](https://rebrickable.com/colors/) page seems to calculate different thing (read [`colors.num_sets`](#colors) description for details).

`min_year` is the year of the set where this color was first used for the parts. Corresponding stat on Rebrickable is "First Year" column on the [part colors](https://rebrickable.com/colors/) page.

`max_year` is the year of the set where parts in this color were last seen. Corresponding stat on Rebrickable is "Last Year" column on the [part colors](https://rebrickable.com/colors/) page.

`num_parts` is total number of these parts in this color across all sets. Corresponding stat on Rebrickable is "Num Parts" column on the [part colors](https://rebrickable.com/colors/) page.

The reason why this view has the same columns as the original [`colors`](#colors) table is that it was introduced before corresponding columns were added to the `colors` table.

`num_parts` here and in the [`colors`](#colors) table may differ (see detailed table in the [output](examples/color_stats_diff.txt) of the "Stats difference in `colors` table" [example](#examples)). How they are calculated here is described in [Stats Tables](#stats-tables) section. How they are calculated on Rebrickable is unspecified.

## rb_db_lov

Columns: `key` (text), `value` (text).

This table contains list of values, which are described in the following sections.

### `schema_version`

Version of the database schema. Just a number without dots or other characters.

It is incremented with each schema modification, regardless of whether this modification is back compatible or not, or whether it is caused by a change in original Rebrickable tables or by some internal change in `rb.db`.

In this case release from the [`latest`]({{ site.github.repository_url }}/releases/tag/latest) tag may not always be preferable, as it may include breaking schema changes without prior notice.

To deliver updates with guarantee against unexpected schema changes `rb.db` uses tags with the schema version. They use format `latest-v<N>` where `<N>` is the schema version, for example [`latest-v5`]({{ site.github.repository_url }}/releases/tag/latest-v5).

The idea is that you start using release with the most recent `latest-v<N>` tag and get updates until schema changes. After it changes nothing breaks on your side, so you just calmly check what changed and switch to the new schema version.

### `data_timestamp`

[UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) (in seconds) when the database was generated.

New `rb.db` is released only when there is new data since the last release, so it is safe to assume that the databases with different `data_timestamp` values have different data, and the one with greater `data_timestamp` contains more relevant data.

# Examples

{% include examples.md %}
