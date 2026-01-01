{% macro json_extract(json_col, path) %}
  {% if target.type == 'bigquery' %}
    json_value({{ json_col }}, '{{ path }}')
  {% elif target.type == 'snowflake' %}
    parse_json({{ json_col }}){{ path | replace('$','') }}::string
  {% else %}
    null
  {% endif %}
{% endmacro %}
