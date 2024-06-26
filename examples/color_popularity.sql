.output color_popularity.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Use "color popularity" coefficient as total number of parts in this color per year normalized by color.

CREATE TEMPORARY VIEW color_popularity
AS
  SELECT 1 + CAST(round(99.0 * log(max(num_parts) OVER (PARTITION BY year), num_parts)) AS INTEGER) popularity
       , *
    FROM (SELECT sum(quantity) num_parts, *
            FROM ___set_parts_for_stats
           GROUP BY color_id, year
         )
    JOIN colors c
      ON c.id = color_id;

-- Print it for all colors in 2018.

SELECT name
     , num_parts
     , popularity
  FROM color_popularity
 WHERE year = 2018
 ORDER BY num_parts DESC;

-- Print it for White and Red for all years.

SELECT year
     , w.popularity white
     , r.popularity red
     , substr(CASE
                WHEN w.popularity > r.popularity
                THEN printf('%.*c', r.popularity, '=') || printf('%.*c', w.popularity - r.popularity, '-')
                WHEN w.popularity < r.popularity
                THEN printf('%.*c', w.popularity, '=') || printf('%.*c', r.popularity - w.popularity, '_')
                ELSE printf('%.*c', w.popularity, '=')
              END, 60, 41) bar
  FROM color_popularity w
  JOIN color_popularity r
 USING (year)
 WHERE w.name = 'White'
   AND r.name = 'Red'
 ORDER BY year DESC;
