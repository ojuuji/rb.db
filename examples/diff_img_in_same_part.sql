.output diff_img_in_same_part.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Parts which have multiple non-`NULL` image URLs in `inventory_parts` table.

SELECT dense_rank() OVER (ORDER BY part_num, color_id) '#'
     , part_num, color_id, img_url, count(DISTINCT set_num) num_sets, set_num 'example set_num'
  FROM inventory_parts ip
  JOIN (SELECT part_num, color_id
          FROM inventory_parts
         GROUP BY 1, 2
        HAVING count(DISTINCT img_url) > 1
        -- use this to include null/non-null differences:
        -- HAVING count(DISTINCT coalesce(img_url, '!')) > 1
       )
 USING (part_num, color_id)
  JOIN inventories i
    ON i.id = ip.inventory_id
 GROUP BY part_num, color_id, img_url
 ORDER BY part_num, color_id, img_url;

-- And parts which have both `NULL` and non-`NULL` image URLs.

SELECT dense_rank() OVER (ORDER BY part_num, color_id) '#'
     , part_num, color_id, img_url, count(DISTINCT set_num) num_sets, set_num 'example set_num'
  FROM inventory_parts ip
  JOIN (SELECT part_num, color_id
          FROM inventory_parts
         GROUP BY 1, 2
        HAVING count(img_url) > 0 AND count(*) > count(img_url)
       )
 USING (part_num, color_id)
  JOIN inventories i
    ON i.id = ip.inventory_id
 GROUP BY part_num, color_id, img_url
 ORDER BY part_num, color_id, img_url;
