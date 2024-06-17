.bail ON
.mode table --wrap 0
.echo ON

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

SELECT DISTINCT set_num, part_num, color_id, img_url
  FROM inventory_parts ip
  JOIN (SELECT part_num, color_id
          FROM inventory_parts
         GROUP BY 1, 2
        HAVING count(DISTINCT coalesce(img_url, '!')) > 1
       )
 USING (part_num, color_id)
  JOIN inventories i
    ON i.id = ip.inventory_id
 ORDER BY 2, 3, 1;
