.output colors_map.json
.bail ON

-- Colors as JSON array of pairs `<id>,{"name":"<name>","sortPos":<sort_pos>}` suitable for JS Map constructor.

SELECT json_group_array(
         json_array(
           id,
           json_object(
             'name', name,
             'sortPos', sort_pos
           )
         ) ORDER BY sort_pos
       )
  FROM colors
  JOIN color_properties
 USING (id)
