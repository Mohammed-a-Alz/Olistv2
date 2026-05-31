{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if target.schema | upper == 'PROD' and custom_schema_name is not none -%}
        {{ target.schema }}_{{ custom_schema_name | trim | upper }}
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}

{%- endmacro %}