.bail ON
.mode table --wrap 0
.echo ON

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Print parts which have multiple non-NULL image URLs

SELECT part_num, color_id, img_url, count(set_num) num_sets, set_num 'example set_num'
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
 GROUP BY 1, 2, 3
 ORDER BY 1, 2, 3;

-- Print parts which have NULL and non-NULL image URLs

SELECT part_num, color_id, img_url, count(set_num) num_sets, set_num 'example set_num'
  FROM inventory_parts ip
  JOIN (SELECT part_num, color_id
          FROM inventory_parts
         GROUP BY 1, 2
        HAVING count(img_url) > 0 AND count(*) > count(img_url)
       )
 USING (part_num, color_id)
  JOIN inventories i
    ON i.id = ip.inventory_id
 GROUP BY 1, 2, 3
 ORDER BY 1, 2, 3;
