{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if target.name == 'PROD' and custom_schema_name is not none -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}

{%- endmacro %}