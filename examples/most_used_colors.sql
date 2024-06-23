.output most_used_colors.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

.mode column --wrap 0
.width 0 -9 -9 -50 -3 -3 0

-- Colors ordered by the total number of parts in this color across all sets, with numbers and histogram.

SELECT name
     , num_parts
     , num_sets
     , printf('%.*c', 1 + round(log(1.4, num_parts) * 49.0 / max_num_parts), '■') num_parts_bar
     , row_number() OVER (ORDER BY num_parts DESC, num_sets DESC) 'np#'
     , row_number() OVER (ORDER BY num_sets DESC, num_parts DESC) 'ns#'
     , printf('%.*c', 1 + round(log(1.3, num_sets) * 49.0 / max_num_sets), '■') num_sets_bar
  FROM color_stats
  JOIN colors c
    ON c.id = color_stats.color_id
 CROSS JOIN (SELECT max(log(1.3, num_sets)) max_num_sets FROM color_stats)
 CROSS JOIN (SELECT max(log(1.4, num_parts)) max_num_parts FROM color_stats)
 ORDER BY num_parts DESC

