.output available_part_colors.html
.bail ON

.print <!--
.mode qbox
SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';
.print -->

.print <!DOCTYPE html><head>
.print <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
.print <body><style>td{vertical-align:middle}</style><table class="table table-striped w-auto"><tbody>

.mode html
.headers ON

-- Table like in "Available Colors" section on Rebrickable part detail pages. Example shows colors for part [`12939`](https://rebrickable.com/parts/12939/).

CREATE TEMPORARY VIEW available_part_colors
AS
  SELECT part_num, name, num_sets, min_year, max_year, num_parts, img_url
    FROM part_color_stats pcs
    JOIN colors c
      ON c.id = pcs.color_id
    JOIN color_properties cp
      ON cp.id = c.id
   ORDER BY cp.sort_pos DESC;

SELECT img_url '', name Color, num_parts 'Set Parts', num_sets 'Sets', min_year 'From', max_year 'To'
  FROM available_part_colors
 WHERE part_num = '12939';

.print <script>const thumbUrl = u => `${u}/85x85p.${u.split('.').pop()}`.replace('/media/parts/', `/media/thumbs/parts/`);
.print document.querySelectorAll('tr>td:first-child').forEach(e=>e.innerHTML=`<img src="${thumbUrl(e.innerHTML)}"></div>`)</script>
.print </tbody></table></body>
