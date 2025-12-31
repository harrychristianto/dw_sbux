
{% macro convert_to_tz(ts_col, tz_name, source_tz='UTC') %}
  {# 
    Snowflake CONVERT_TIMEZONE syntax:
    - CONVERT_TIMEZONE(<target_tz>, <timestamp>)
    - CONVERT_TIMEZONE(<source_tz>, <target_tz>, <timestamp>)
    If your raw timestamps are UTC (common in ELT), use the 3-arg form.
  #}
  {% if target.type == 'snowflake' %}
    CONVERT_TIMEZONE('{{ source_tz }}', '{{ tz_name }}', {{ ts_col }})
  {% elif target.type == 'bigquery' %}
    DATETIME(TIMESTAMP({{ ts_col }}), '{{ tz_name }}')
  {% else %}
    {{ ts_col }}
  {% endif %}
{% endmacro %}
