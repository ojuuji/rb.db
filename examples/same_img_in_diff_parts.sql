.output same_img_in_diff_parts.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Different parts (i.e. parts with different `part_num` regardless of color) having the same image.

SELECT row_number() OVER () '#'
     , dense_rank() OVER (ORDER BY img_url) 'img#'
     , set_num example_set_num
     , count(DISTINCT set_num) num_sets
     , part_num
     , color_id example_color_id
     , count(DISTINCT color_id) num_colors
     , img_url
  FROM (SELECT img_url
          FROM inventory_parts
         GROUP BY img_url
        HAVING count(DISTINCT part_num) > 1
       ) t
  JOIN inventory_parts ip
 USING (img_url)
  JOIN inventories i
    ON i.id = ip.inventory_id
 GROUP BY part_num, img_url
 ORDER BY img_url, part_num;
