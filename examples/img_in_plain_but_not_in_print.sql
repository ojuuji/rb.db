.output img_in_plain_but_not_in_print.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Printed parts, which do not have image, while their unprinted counterparts have them.

SELECT row_number() OVER () '#'
     , set_num example_set_num
     , ip.part_num part_num
     , ip.color_id color_id
     , pip.part_num plain_part_num
     , pip.img_url img_url
  FROM inventories i
  JOIN inventory_parts ip
    ON ip.inventory_id = i.id
  JOIN part_relationships r
    ON r.child_part_num = ip.part_num
   AND r.rel_type = 'P'
  JOIN inventory_parts pip
    ON pip.part_num = r.parent_part_num
   AND pip.color_id = ip.color_id
 WHERE ip.img_url IS NULL
   AND pip.img_url IS NOT NULL
 GROUP BY 3, 4, 5
 ORDER BY 3, 4, 5;
