
{% macro surrogate_key(cols) %}
  {% if target.type == 'bigquery' %}
    to_hex(md5(concat({{ ','.join(cols) }})))
  {% else %}
    md5({{ ' || '.join(cols) }})
  {% endif %}
{% endmacro %}
