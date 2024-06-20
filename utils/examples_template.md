Description|SQL|Output
---|---|---
{% for e in examples -%}
{{ e.desc }}|[{{ e.sql }}](examples/{{ e.sql }})|{% if e.out %}[{{ e.out }}](examples/{{ e.out }}){% endif %}
{% endfor %}