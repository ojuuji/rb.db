.output color_popularity.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

.mode column --wrap 0

-- Colors popularity in sets.

SELECT name
     , num_parts
     , printf('%.*c', ceil(log(1.4, num_parts)), '■') bar
     , row_number() OVER (ORDER BY num_parts DESC, num_sets DESC) 'parts_rank'
     , row_number() OVER (ORDER BY num_sets DESC, num_parts DESC) 'sets_rank'
     , num_sets
     , printf('%.*c', ceil(log(1.3, num_sets)), '■') bar
  FROM color_stats
  JOIN colors c
    ON c.id = color_stats.color_id
 ORDER BY num_parts DESC

