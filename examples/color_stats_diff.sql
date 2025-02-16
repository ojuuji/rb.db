.output color_stats_diff.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Stats difference in `colors` table ('c.'), `color_stats` view ('cs.') and `part_color_stats` view ('pcs.').

SELECT id
     , name
     , c.num_parts 'c.num_parts'
     , cs.num_parts 'cs.num_parts'
     , c.num_parts - cs.num_parts 'c-cs'
     , c.num_sets 'c.num_sets'
     , cs.num_sets 'cs.num_sets'
     , c.num_sets - cs.num_sets 'c-cs'
     , sum(pcs.num_sets)
     , c.num_sets - sum(pcs.num_sets) 'c-pcs'
     , CAST(c.y1 AS TEXT) || '-' || CAST(cs.min_year AS TEXT) || '=' || CAST(c.y1-cs.min_year AS TEXT) 'minyear:c-cs'
     , CAST(c.y2 AS TEXT) || '-' || CAST(cs.max_year AS TEXT) || '=' || CAST(c.y2-cs.max_year AS TEXT) 'maxyear:c-cs'
  FROM colors c
  JOIN color_stats cs
    ON c.id = cs.color_id
  JOIN part_color_stats pcs
    ON c.id = pcs.color_id
 GROUP BY id;
