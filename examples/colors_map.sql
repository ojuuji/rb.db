.output colors_map.json
.bail ON

-- JSON array of colors in form `[<id>,{"name":"<name>","sortPos":<sort_pos>}]` suitable for JS Map constructor.

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
