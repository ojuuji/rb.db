.output similar_to_given_color_sorted.html
.bail ON

.print <!--
.mode qbox
SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';
.print -->

.print <!DOCTYPE html>
.print <body><style>td{min-width:100px}</style><table><tbody>

.mode html

-- Colors, similar to the given one (`Pastel Blue` in this example), ordered naturally, so the given one usually will be somewhere in the middle.

SELECT sc.name, '#' || sc.rgb
  FROM colors c
  JOIN similar_colors sc
    ON c.id = sc.ref_id
  JOIN color_properties cp
    ON cp.id = sc.id
 WHERE c.name = 'Pastel Blue' and sc.id != 9999
 ORDER BY cp.sort_pos;

.print <script>document.querySelectorAll('td+td').forEach(e=>{e.style.background=e.innerHTML;e.innerHTML=''})</script>
.print </tbody></table></body>
