
{% macro convert_to_tz(ts_col, tz_name) %}
  {% if target.type == 'bigquery' %}
    datetime(timestamp({{ ts_col }}), '{{ tz_name }}')
  {% elif target.type == 'snowflake' %}
    convert_timezone('{{ tz_name }}', {{ ts_col }})
  {% else %}
    {{ ts_col }}
  {% endif %}
{% endmacro %}
