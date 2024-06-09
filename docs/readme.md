
- [Rebrickable Tables](#rebrickable-tables)
  - [colors](#colors)
  - [parts](#parts)
  - [part_relationships](#part_relationships)
    - [`A` - Alternate](#a---alternate)
    - [`B` - Sub-Part](#b---sub-part)
    - [`M` - Mold](#m---mold)
    - [`P` - Print](#p---print)
    - [`R` - Pair](#r---pair)
    - [`T` - Pattern](#t---pattern)
- [Custom Tables](#custom-tables)
  - [colors_order](#colors_order)
  - [part_rels_resolved](#part_rels_resolved)

The main goal of `rb.db` is to provide original, unmodified tables from [Rebrickable Downloads](https://rebrickable.com/downloads/) in a form of ready-to-use SQLite database file, built on schedule, so the latest release provides always up-to-date version of the database.

Releases are built automatically on a schedule and follow this retention policy:
- git tag [`latest`](https://github.com/ojuuji/rb.db/releases/tag/latest) is always recreated when releasing new version, so the links to the latest version are always the same
- [`releases`](https://github.com/ojuuji/rb.db/releases) retain the last 10 releases
- for older releases is retained the latest release of the month

# Database Schema

For Rebrickable tables the main rule is to import them as-is, without adding/removing/modifying any table/column names or data. Schema only enforces several constraints to ensure the database integrity and the relevance of this documentation:
- foreign key constraints for all columns which reference other tables
- value constraints (from `NOT NULL` to more specific whenever possible)
- rigid typing via SQLite [STRICT tables](https://www.sqlite.org/stricttables.html)

As to data types, schema uses only INTEGER and TEXT because of the following reasons:
- to avoid possible confusion, as data types like `VARCHAR(N)` do not really apply any constraints in SQLite ([docs](https://www.sqlite.org/datatype3.html))
- rigid typing allows only few data types so it was (fortunately) not much of a choice

Schema of the [Rebrickable Tables](#rebrickable-tables) is described in the section of the same name. In addition to Rebrickable tables `rb.db` includes few custom tables, non-trivially generated from them. They are described in [Custom Tables](#custom-tables) section.

Almost all columns in Rebrickable tables cannot be `NULL`. Thus this is not mentioned in the columns description, and only for nullable columns there will be explicit note about this.

#### Note about import from CSV

Original Rebrickable tables are provided in CSV format. SQLite [can import](https://sqlite.org/cli.html#importing_files_as_csv_or_other_formats) tables from CSV files directly. However it unconditionally treats empty values as empty strings ([details](https://sqlite.org/forum/forumpost/9da85fe4fc6760c4)) whereas in context of Rebrickable tables these values have to become `NULL` in database.

For example, [`theme.parent_id`](#theme) foreign key constraint would even fail with an empty string because it expect either an existing `theme.id` value or `NULL`.

This is why the import scripts import tables directly instead of relying on `.import` SQLite command.

# Rebrickable Tables

## colors

Columns: `id` (primary key), `name`, `rgb`, `is_trans`.

`id` is a number, unique for each color. In other tables colors are referenced by this number.

`name` is the color name on Rebrickable.

`rgb` is RGB color in a form of [HEX triplet](https://en.wikipedia.org/wiki/Web_colors#Hex_triplet), 6 hexadecimal digits, no prefix.

`is_trans` is a flag indicating if color is transparent. Possible values: `t` for transparent colors and `f` otherwise.

Examples:

```
236,Trans-Light Purple,96709F,t
272,Dark Blue,0A3463,f
```

## parts

Columns: `part_num` (primary key), `name`, `part_cat_id`, `part_material`.

`part_num` is alpha-numeric part number uniquely identifying each part on Rebrickable. In other tables parts are referenced by this part number.

`name` is the part name on Rebrickable.

`part_cat_id` is an reference (foreign key) to [`part_categories.id`](#part-categories) column.

`part_material` is the material from which this part is made. Possible options:

```
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

Rebrickable uses this relation in the build matching option _"Consider alternate parts that can usually be used as replacements, but are not always functionally compatible."_

There will be no corresponding row `A,62531,11954` so this relation should be considered bidirectional.

### `B` - Sub-Part

Example: `B,6051,6051c04`

[6051](https://rebrickable.com/parts/6051/) is a sub-part of [6051c04](https://rebrickable.com/parts/6051c04/).

### `M` - Mold

Example: `M,92950,3455`

[92950](https://rebrickable.com/parts/92950/) and [3455](https://rebrickable.com/parts/3455/) are essentially the same parts where 92950 is a newer mold. For 3455 Rebrickable says it is superseded by 92950.

Rebrickable uses this relation in the build matching option _"Ignore mold variations in parts."_

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

But there are no row `M,93571,67695`. For the info, `67695` is the latest mold.

Moreover, alternates not necessarily point to the latest molds, and they may have molds too (as mentioned above, 32174 is an older mold of 67695):

```
A,60176,32174
M,89652,60176
```

### `P` - Print

Example: `P,4740pr0014,4740`

[4740pr0014](https://rebrickable.com/parts/4740pr0014/) is a print of [4740](https://rebrickable.com/parts/4740/).

Rebrickable uses this relation along with relation `T` in the build matching option _"Ignore printed and patterned part differences."_

### `R` - Pair

Example: `R,18947,35188`

[18947](https://rebrickable.com/parts/18947/) pairs with [35188](https://rebrickable.com/parts/35188/). And vice versa.

There will be no corresponding row `R,35188,18947` so this relation should be considered bidirectional.

### `T` - Pattern

Example: `T,19858pat0002,19858`

[19858pat0002](https://rebrickable.com/parts/19858pat0002/) is a pattern of [19858](https://rebrickable.com/parts/19858/).

Rebrickable uses this relation along with relation `P` in the build matching option _"Ignore printed and patterned part differences."_

# Custom Tables

These tables are non-trivially generated, i.e. their data cannot be obtained using, for example, some sophisticated `SELECT` statement.

## colors_order

Columns: `position` (primary key), `color_id`.

`position` is a color position in a sorted list of colors.

`color_id` is a reference (foreign key) to [`colors.id`](#colors) column.

This table is used to sort by colors. For example, to sort parts with the same part number but different colors.

Colors are ordered the following way:
1. `[Unknown]`
2. `[No Color/Any Color]`
3. `White`
4. `Black`
5. Grayscale colors from darker to lighter
6. Remaining colors, ordered by [hue](https://en.wikipedia.org/wiki/Hue)

This order of the colors tries to mimic the one in _"Your Colors"_ section on the part pages on Rebrickable.

## part_rels_resolved

Columns: `rel_type`, `child_part_num`, `parent_part_num`.

This is a processed [`part_relationships`](#part_relationships) table with the same set of columns (see columns description there).

As a result of processing it lists so-called _"resolved"_ relationships. The way they are resolved is described below:
- retain ony relationships [`A`](#a---alternate) and [`M`](#m---mold), as only these are subject of resolving (i.e. other rows would be the same as in `part_relationships`)
- in case of molds resolve them the following way (read related details in [`M` - Mold](#m---mold) section):
  - always list the successor part as `parent_part_num`
  - use the final successor part for all molds, i.e. if there are molds A→B and A→C, and the final successor is C, table will have A→C and B→C
  - as a successor use the part which either has greater end year, or greater start year, or the part that is referenced in more sets
- in case of alternates:
  - first resolve molds for both `child_part_num` and `parent_part_num`
  - as `parent_part_num` use part which either has greater end year, or the part that is referenced in more sets.

This way to resolve any `A`/`M` relationship it is enough to perform single lookup in this table. I.e. for any relationship `X` and part `Y` there will be either zero or one row `X,Y,Z` and no rows starting with `X,Z,` where `X` is either `A` or `M`.
