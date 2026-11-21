{% macro precipitation_band(col) %}
case
    when {{ col }} is null then null
    when {{ col }} < 0.1 then 'none'
    when {{ col }} < 2.5 then 'light'
    when {{ col }} < 7.6 then 'moderate'
    else 'heavy'
end
{% endmacro %}

{% macro wind_gust_band(col) %}
case
    when {{ col }} is null then null
    when {{ col }} < 30 then 'calm'
    when {{ col }} < 50 then 'windy'
    else 'strong'
end
{% endmacro %}

{% macro is_freezing(col) %}
({{ col }} <= 0)
{% endmacro %}