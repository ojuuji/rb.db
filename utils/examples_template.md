Description|Source|Output
---|---|---
{% for e in examples -%}
{{ e.desc }}|[[`sql`](examples/{{ e.sql }})]|{% if e.out %}[[`{{ e.ext }}`](examples/{{ e.out }})]{% endif %}
{% endfor %}
