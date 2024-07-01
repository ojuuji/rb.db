.output part_canonical_urls.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Canonical URLs for the part detail pages.

/*
  As the canonical part detail URLs Rebrickable uses URLs of form
  https://rebrickable.com/parts/<part_num>/<kebab-case-part-name>/
  but actually the part name can be any or even omitted at all:
  https://rebrickable.com/parts/<part_num>/ (trailing '/' better to leave to
  avoid HTTP 301 redirect). After opening URL Rebrickable replaces it in the
  address bar with the canonical one without extra HTTP request.

  For the part color URLs Rebrickable uses URLs like
  https://rebrickable.com/parts/<part_num>/<kebab-case-part-name>/<color_id>/
  and, while <kebab-case-part-name> cannot be omitted this time, there still can
  be used any text in place of it. So URLs like, for example,
  https://rebrickable.com/parts/<part_num>/colors/<color_id>/ work just fine.

  So there is no real need for canonical URLs in the custom schema, and they are
  provided as an example instead.
*/

CREATE TEMPORARY VIEW part_names_hyphenated
AS
  WITH RECURSIVE rec(part_num, name, name_hyphenated, i)
    AS (SELECT part_num, name, '', 1
          FROM parts
         UNION ALL
        SELECT part_num
             , name
             , name_hyphenated
            || CASE
                 WHEN substr(name, i, 1) GLOB '[a-zA-Z0-9]'
                 THEN lower(substr(name, i, 1))
                 WHEN substr(name, i, 1) = ' '
                  AND substr(name_hyphenated, length(name_hyphenated), 1) != '-'
                 THEN '-'
                 ELSE ''
               END
             , i + 1
          FROM rec
         WHERE i <= length(name)
       )
SELECT part_num, name, name_hyphenated
  FROM rec
 WHERE i > length(name);

CREATE TEMPORARY VIEW part_canonical_urls
AS
  SELECT part_num
       , name
       , 'https://rebrickable.com/parts/' || part_num || '/' || name_hyphenated || '/' url
    FROM part_names_hyphenated;

.mode line

SELECT *
  FROM part_canonical_urls
 ORDER BY part_num
 LIMIT 1000;
