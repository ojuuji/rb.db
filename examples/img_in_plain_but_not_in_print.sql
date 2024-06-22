.output img_in_plain_but_not_in_print.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Printed parts which do not have image while plain parts in the same color has one.

SELECT row_number() OVER () '#'
     , set_num example_set_num
     , ip.part_num part_num
     , ip.color_id color_id
     , pip.part_num plain_part_num
     , pip.img_url img_url
  FROM inventory_parts ip
  JOIN inventories i
    ON i.id = ip.inventory_id
  JOIN inventory_parts pip
    ON substr(ip.part_num, 1, instr(ip.part_num, 'pr') - 1) = pip.part_num
   AND ip.color_id = pip.color_id
 WHERE ip.img_url IS NULL
   AND ip.part_num LIKE '%pr%'
   AND pip.img_url IS NOT NULL
 GROUP BY 3, 4, 5
 ORDER BY 3, 4, 5;
