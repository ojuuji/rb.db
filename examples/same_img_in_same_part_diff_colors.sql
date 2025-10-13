.output same_img_in_same_part_diff_colors.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Same parts in different colors having the same image.

  WITH combos
    AS (SELECT img_url, part_num, color_id
             , set_num example_set_num
             , count(DISTINCT set_num) num_sets
          FROM inventory_parts ip
          JOIN inventories i
            ON i.id = ip.inventory_id
         GROUP BY 1, 2, 3
       )
SELECT row_number() OVER () '#'
     , dense_rank() OVER (ORDER BY img_url) 'img#'
     , c.part_num
     , c.color_id color_id1
     , c.example_set_num example_set_num1
     , c.num_sets num_sets1
     , c2.color_id color_id2
     , c2.example_set_num example_set_num2
     , c2.num_sets num_sets2
     , img_url
  FROM combos c
  JOIN combos c2
 USING (part_num, img_url)
 WHERE c.color_id < c2.color_id;
