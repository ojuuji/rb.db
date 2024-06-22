.output same_img_in_multi_parts.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Multiple parts having the same image. So these will be "similar parts" along with their origin.

SELECT row_number() OVER () '#'
     , dense_rank() OVER (ORDER BY img_url) 'img#'
     , set_num example_set_num
     , count(DISTINCT set_num) num_sets
     , part_num
     , color_id
     , c.name color_name
     , img_url
  FROM (SELECT img_url
          FROM inventory_parts
         GROUP BY img_url
        HAVING count(DISTINCT part_num) > 1
            OR count(DISTINCT color_id) > 1
       ) t
  JOIN inventory_parts ip
 USING (img_url)
  JOIN inventories i
    ON i.id = ip.inventory_id
  JOIN colors c
    ON c.id = ip.color_id
 GROUP BY part_num, color_id, img_url
 ORDER BY img_url, part_num, color_id;
