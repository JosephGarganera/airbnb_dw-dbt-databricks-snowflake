{% macro tag(col_name) -%}
    case 
        when {{ col_name }} < 100 then 'low'
        when {{ col_name }} < 200 then 'medium'
        else 'high'
    end
{%- endmacro %}