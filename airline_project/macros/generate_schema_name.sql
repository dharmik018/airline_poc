{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}  {# no custom schema: use the default (silver) #}
    {%- else -%}
        {{ custom_schema_name | trim }}  {# custom schema: use it exactly, for example gold #}
    {%- endif -%}
{%- endmacro %}