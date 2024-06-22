.output num_sets_over_years.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

.mode column --wrap 0

-- Sets per year in numbers and histogram.

SELECT year
     , count(DISTINCT set_num) num_sets
     , printf('%.*c', 1 + count(DISTINCT set_num) / 10, '*') bar
  FROM sets
 GROUP BY year

