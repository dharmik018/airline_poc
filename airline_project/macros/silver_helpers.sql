{% macro text_to_int(column_name) %}
    cast(try_cast(trim({{ column_name }}) as double) as int)
{% endmacro %}

{% macro text_to_flag(column_name) %}
    (try_cast(trim({{ column_name }}) as double) = 1)
{% endmacro %}

{% macro hhmm_to_minutes(column_name) %}
    case
        when try_cast(trim({{ column_name }}) as double) is null then null
        when try_cast(trim({{ column_name }}) as double) < 0 then null
        when try_cast(trim({{ column_name }}) as double) > 2400 then null
        when try_cast(trim({{ column_name }}) as double) % 100 >= 60 then null
        else cast(
            floor(try_cast(trim({{ column_name }}) as double) / 100) * 60
            + try_cast(trim({{ column_name }}) as double) % 100
            as int)
    end
{% endmacro %}