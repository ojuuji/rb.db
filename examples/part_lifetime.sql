.output part_lifetime.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

.mode column --wrap 0

-- Part lifetime in numbers and histogram.

SELECT max_year - min_year + 1 num_years
     , count(*) num_parts
     , printf('%.*c', ceil(log(1.1, count(*) + 1)), '█') bar
  FROM part_stats
 GROUP BY num_years

