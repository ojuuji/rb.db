
- [Database Schema](#database-schema)
- [Rebrickable Tables](#rebrickable-tables)
  - [colors](#colors)
  - [themes](#themes)
  - [parts](#parts)
  - [part_relationships](#part_relationships)
    - [`A` - Alternate](#a---alternate)
    - [`B` - Sub-Part](#b---sub-part)
    - [`M` - Mold](#m---mold)
    - [`P` - Print](#p---print)
    - [`R` - Pair](#r---pair)
    - [`T` - Pattern](#t---pattern)
- [Custom Tables](#custom-tables)
  - [color_properties](#color_properties)
  - [similar_colors](#similar_colors)
  - [part_rels_resolved](#part_rels_resolved)
  - [part_rels_extra](#part_rels_extra)
  - [rb_db_lov](#rb_db_lov)

{% include download.html %}

The main goal of `rb.db` is to provide original, unmodified tables from [Rebrickable Downloads](https://rebrickable.com/downloads/) in a form of ready-to-use SQLite database file, and build it on schedule, so the latest release provides always up-to-date version of the database.

Releases are created automatically once a day, but only if there were actual changes since the last release.

Retention policy:
- git tag [`latest`]({{ site.github.repository_url }}/releases/tag/latest) is always recreated when releasing new version, so the links to the latest version are always the same
- the last 10 releases are retained unconditionally
- for older releases is retained the latest release of the month

# Database Schema

For Rebrickable tables the main rule is to import them as-is, without adding/removing/modifying any table/column names or data. Schema only enforces several constraints to ensure the database integrity and the relevance of this documentation:
- foreign key constraints for all columns which reference other tables
- value constraints (from `NOT NULL` to more specific whenever possible)
- rigid typing via SQLite [STRICT tables](https://www.sqlite.org/stricttables.html)

As to data types, schema uses only INTEGER and TEXT because of the following reasons:
- to avoid possible confusion, as the data types like `VARCHAR(N)` do not really imply any constraints in SQLite ([docs](https://www.sqlite.org/datatype3.html))
- rigid typing allows only a few data types, so it was (fortunately) not much of a choice

Schema of the [Rebrickable Tables](#rebrickable-tables) is described in the section of the same name. In addition to Rebrickable tables `rb.db` includes few custom tables, non-trivially generated from them. They are described in [Custom Tables](#custom-tables) section.

Almost all columns in Rebrickable tables cannot be `NULL`. Thus this is not mentioned in the columns description, and only for nullable columns there will be explicit note about this.

#### Note about import from CSV

Original Rebrickable tables are provided in CSV format. SQLite [can import](https://sqlite.org/cli.html#importing_files_as_csv_or_other_formats) tables from CSV files directly. However it unconditionally treats empty values as empty strings ([details](https://sqlite.org/forum/forumpost/9da85fe4fc6760c4)) whereas in context of Rebrickable tables these values have to become `NULL` in database.

For example, [`themes.parent_id`](#themes) foreign key constraint would fail at all with an empty string, because it expects either an existing `themes.id` value or `NULL`.

This is why the import scripts import tables directly instead of relying on `.import` SQLite command.

# Rebrickable Tables

## colors

This table contains the [part colors](https://rebrickable.com/help/colors/).

Columns: `id` (primary key), `name`, `rgb`, `is_trans`.

`id` is a number, unique for each color. In other tables colors are referenced by this number.

`name` is the color name on Rebrickable.

`rgb` is RGB color in a form of [HEX triplet](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), 6 hexadecimal digits, no prefix.

`is_trans` is a flag indicating if color is transparent. Possible values: `t` ("true") for transparent colors and `f` ("false") otherwise.

Example:

```
$ sqlite3 rb.db "select * from colors group by is_trans"
-1|[Unknown]|0033B2|f
32|Trans-Black IR Lens|635F52|t
```

## themes

This table contains the [sets themes](https://rebrickable.com/help/set-themes/).

Columns: `id` (primary key), `name`, `parent_id` (nullable).

`id` is a number, unique for each theme. In other tables, and even in the same table in `parent_id` column, themes are referenced by this number.

`name` is the theme name on Rebrickable.

`parent_id` is the parent theme id for sub-themes and `NULL` otherwise.

As for now, the maximum length of themes chain is **3** (A→B→C).

Example:

```
$ sqlite3 -nullvalue NULL rb.db "select * from themes where 52 in (id, parent_id) limit 2"
52|City|NULL
53|Airport|52
```

## parts

Columns: `part_num` (primary key), `name`, `part_cat_id`, `part_material`.

`part_num` is alpha-numeric part number uniquely identifying each part on Rebrickable. In other tables parts are referenced by this part number.

Although uncommon, part numbers may also contain a dot ([75c23.75](https://rebrickable.com/parts/75c23.75/)) and a hyphen ([134916-740](https://rebrickable.com/parts/134916-740/)).

`name` is the part name on Rebrickable.

`part_cat_id` is an reference (foreign key) to [`part_categories.id`](#part_categories) column.

`part_material` is the material from which this part is made. Possible values:

```
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

Columns: `rel_type`, `child_part_num`, `parent_part_num`.

Each row defines single relationship between two parts `child_part_num` and `parent_part_num`, which both are references (foreign keys) to [`parts.part_num`](#parts) column.

`rel_type` is a relationship type, defined by a single character, one of: `ABMPRT`. They all are described below.

### `A` - Alternate

Example: `A,11954,62531`

For [11954](https://rebrickable.com/parts/11954/) Rebrickable will say it is usable as alternate for the [62531](https://rebrickable.com/parts/62531/). And vice versa.

Rebrickable uses this relationship in the build matching option _"Consider alternate parts that can usually be used as replacements, but are not always functionally compatible."_

There will be no corresponding row `A,62531,11954` so this relationship should be considered bidirectional.

### `B` - Sub-Part

Example: `B,6051,6051c04`

[6051](https://rebrickable.com/parts/6051/) is a sub-part of [6051c04](https://rebrickable.com/parts/6051c04/).

### `M` - Mold

Example: `M,92950,3455`

[92950](https://rebrickable.com/parts/92950/) and [3455](https://rebrickable.com/parts/3455/) are essentially the same parts where 92950 is a newer mold. For 3455 Rebrickable says it is superseded by 92950.

Rebrickable uses this relationship in the build matching option _"Ignore mold variations in parts."_

The successor part is not necessarily listed as `child_part_num`. And an older part is not necessarily listed as `parent_part_num`. Here are two examples in the form `child_part_num (year_from, year_to) -> parent_part_num (year_from, year_to)`:

```
60608 (2007, <present>) -> 3854 (1978, 2008)
3002a (1954, 1990) -> 3002 (1979, <present>)
```

In case of multiple molds not all combinations are listed. For example, for parts [67695](https://rebrickable.com/parts/67695/), [93571](https://rebrickable.com/parts/93571/), [32174](https://rebrickable.com/parts/32174/) there are two rows:

```
M,93571,32174
M,67695,32174
```

But there are no row `M,93571,67695` (for the info, `67695` is the latest mold).

Also, alternates not necessarily point to the latest molds, and they may have molds too (as mentioned above, 32174 is an older mold of 67695):

```
A,60176,32174
M,89652,60176
```

### `P` - Print

Example: `P,4740pr0014,4740`

[4740pr0014](https://rebrickable.com/parts/4740pr0014/) is a print of [4740](https://rebrickable.com/parts/4740/).

Rebrickable uses this relationship along with relationship `T` in the build matching option _"Ignore printed and patterned part differences."_

### `R` - Pair

Example: `R,18947,35188`

[18947](https://rebrickable.com/parts/18947/) pairs with [35188](https://rebrickable.com/parts/35188/). And vice versa.

There will be no corresponding row `R,35188,18947` so this relationship should be considered bidirectional.

### `T` - Pattern

Example: `T,19858pat0002,19858`

[19858pat0002](https://rebrickable.com/parts/19858pat0002/) is a pattern of [19858](https://rebrickable.com/parts/19858/).

Rebrickable uses this relationship along with relationship `P` in the build matching option _"Ignore printed and patterned part differences."_

# Custom Tables

These tables are non-trivially generated, i.e. their data cannot be obtained using, for example, some simple query statement.

## color_properties

Columns: `id` (primary key), `sort_pos`.

`id` is a reference (foreign key) to [`colors.id`](#colors) column.

`sort_pos` is a color position in a sorted list of colors. It is designed to help sorting parts by color.

With the `sort_pos` colors are ordered the following way:
1. `[Unknown]`
2. `[No Color/Any Color]`
3. `White`
4. `Black`
5. Grayscale colors from darker to lighter
6. Remaining colors, ordered by [hue](https://en.wikipedia.org/wiki/Hue)

It is based on the colors order used in _"Your Colors"_ section on the part pages on Rebrickable.

Example:
```
$ sqlite3 -csv rb.db "select id, name from colors natural join color_properties p order by p.sort_pos limit 10"
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

Columns: `ref_id`, `ref_name`, `id`, `name`, `rgb`, `is_trans`.

This table lists similar colors for every color. It is inspired by Rebrickable build matching option _"Part color sensitivity" → "Parts that have similar colors will be matched."_ though results may be different.

`ref_id` and `id` are references (foreign keys) to [`colors.id`](#colors) column. Technically `similar_colors` is a view to `similar_color_ids`, which contains just these two columns and joined `colors` table on both of them.

Column `ref_id` is indexed, so it is better to search by it instead of `id`. For every pair of similar colors `X→Y` table also contains pair `Y→X` so it is really enough to search only by `ref_id` or `ref_name`.

Additional rules apply:
- `[Unknown]` color is never similar to any color
- `[No Color/Any Color]` color is similar to all colors
- any other color is similar also to itself i.e. there will be row with `ref_id = id`

Whether two colors are similar is determined using Delta E metric. [Here](https://zschuessler.github.io/DeltaE/learn/) is great reading about it. Specifically is used _"dE00"_ algorithm and the maximum Delta E value `20`. For those curious, [Delta E chart for Rebrickable colors](delta_e_chart.html).

Example:
```
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

Columns: `rel_type`, `child_part_num`, `parent_part_num`.

This is a processed [`part_relationships`](#part_relationships) table with the same set of columns (see columns description there).

As a result of processing it lists so-called _"resolved"_ relationships, which are calculated this way:
- retain ony relationships [`A`](#a---alternate) and [`M`](#m---mold), as only these are subject of resolving (i.e. other rows would be the same as in `part_relationships`)
- in case of molds resolve them the following way (read related details in [`M` - Mold](#m---mold) section):
  - always list the successor part as `parent_part_num`
  - use the final successor part for all molds, i.e. if there are molds A→B and A→C, and the final successor is C, table will have A→C and B→C
  - as a successor use the part which either has greater last year, or greater first year, or the part that is referenced in more sets
- in case of alternates:
  - first resolve molds for both `child_part_num` and `parent_part_num`
  - as `parent_part_num` use part which either has greater last year, or the part that is referenced in more sets.

This way to resolve any `A`/`M` relationship it is enough to perform single lookup in this table. I.e. for any relationship `X` and part `Y` there will be either zero or one row `X,Y,Z` and no rows starting with `X,Z,` where `X` is either `A` or `M`.

## part_rels_extra

Columns: `rel_type`, `child_part_num`, `parent_part_num`.

This table defines extra relationships, not available on Rebrickable and maintained within `rb.db`.

Rebrickable does not introduce fictive parts as "common denominators" for other parts. For example, [`35074pr0003`](https://rebrickable.com/parts/35074pr0003/) and [`35074pr0009`](https://rebrickable.com/parts/35074pr0009/) are clearly prints of the same part but unprinted part `35074` does not exist and thus is not listed in Rebrickable tables.

It is interesting that such parts actually exist on the site to some extent. For example, although [`35074`](https://rebrickable.com/parts/35074/) results in _"404 Page Not Found"_, this part is listed as print of [`35074pr0003`](https://rebrickable.com/parts/35074pr0003/) with _"INACTIVE"_ word, appended to its name, and with a note that _"This part is disabled and cannot be used."_.

There are exceptions though. For example, part [`973c00`](https://rebrickable.com/parts/973c00/) does not seem to exist and is only used as a related part for other parts.

So basically `part_rels_extra` table contains relationships, made using "common denominator" parts described above, and several extra alternates.

Content of this table is generated using the rules defined in [`part_rels_extra_rules.txt`]({{ site.github.repository_url }}/blob/master/build/part_rels_extra_rules.txt). See description in this file for details.

Relationships involving "common denominator" parts there can be summarized the following way:

- for every print there will be non-printed part. For example, part [35074pr0003](https://rebrickable.com/parts/35074pr0003/) results in a row `P,35074pr0003,35074` even if part `35074` does not exist
- the same is done for patterns but _after_ prints are removed. For example, for part [`100662pat0001pr0002`](https://rebrickable.com/parts/100662pat0001pr0002/) there will be rows `P,100662pat0001pr0002,100662pat0001` and `T,100662pat0001,100662` but not `P,100662pat0001pr0002,100662pr0002`. Also note that in the pattern row both parts do not actually exist
- minifig torsos and legs, after prints and patterns are removed, are additionally linked as alternates to `973c00` and `970c00` when reasonable.

When building this table, relationship is not added if it already exists in [`part_rels_resolved`](#part_rels_resolved) (for `rel_type` values `A`, `M`) or in [`part_relationships`](#part_relationships) (for the rest of `rel_type` values).

So `part_rels_extra` table complements both these tables. In other words, this union does not have duplicate rows:
```
SELECT *
  FROM part_relationships
 WHERE rel_type NOT IN ('A', 'M')
 UNION
SELECT *
  FROM part_rels_resolved
 WHERE rel_type IN ('A', 'M')
 UNION
SELECT *
  FROM part_rels_extra
```

## rb_db_lov

Columns: `key`, `value`.

This table contains the following list of values:

key|value
---|---
`schema_version`|Version of the database schema. It is incremented with each schema modification, regardless of whether this modification is back compatible or not.
`data_timestamp`|[UNIX timestamp](https://en.wikipedia.org/wiki/Unix_time) (in seconds) when the database was generated. New `rb.db` is released only when there is new data since the last release, so it is safe to assume that the databases with different `data_timestamp` values have different data.
