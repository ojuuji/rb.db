.output printed_part_num_suffixes.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- All suffix formats of printed part_num in a form where every letter and digit are replaced with `x` and `N`. For example, both `3009pr0027e` and `4555c02pr0001a` will have suffix `NNNNx`.

  WITH RECURSIVE t(part_num, suffix, i)
    AS (SELECT part_num, substr(part_num, 2 + instr(part_num, 'pr')), 1
          FROM parts
         WHERE instr(part_num, 'pr') > 1
         UNION ALL
        SELECT part_num, substr(suffix, 1, i - 1) || 'N' || substr(suffix, i + 1), i + 1
          FROM t
         WHERE substr(suffix, i, 1) GLOB '[0-9]'
         UNION ALL
        SELECT part_num, substr(suffix, 1, i - 1) || 'x' || substr(suffix, i + 1), i + 1
          FROM t
         WHERE substr(suffix, i, 1) GLOB '[a-zA-Z]'
       )
SELECT suffix
     , count(DISTINCT part_num) num_part_nums
     , part_num example_part_num
     , 'https://rebrickable.com/parts/' || part_num || '/' part_url
  FROM t
 WHERE length(suffix) = i - 1
 GROUP BY suffix
 ORDER BY num_part_nums DESC;
