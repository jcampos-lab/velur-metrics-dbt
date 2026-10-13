{#
  Money arrives as decimal strings ("49.00"). It is parsed as DECIMAL, never as a float,
  and stored as integer cents. The source tests (is_money_string) reject anything that
  is not a plain amount with at most two decimals before it gets here.
#}
{% macro to_cents(column) -%}
    cast(cast({{ column }} as decimal(18, 2)) * 100 as bigint)
{%- endmacro %}


{# A UTC instant becomes the store's own calendar day. #}
{% macro local_date(timestamp_expression) -%}
    cast(({{ timestamp_expression }}) at time zone '{{ var("store_timezone") }}' as date)
{%- endmacro %}


{# The same pseudonym Velur uses: sha256("salt:id"), first 16 hex characters. #}
{% macro pseudonymize(column) -%}
    left(sha256('{{ var("customer_salt") }}' || ':' || {{ column }}), 16)
{%- endmacro %}


{#
  Round half up, the way JavaScript's Math.round does it (ties go toward +infinity,
  so -2.5 rounds to -2). The production engine is TypeScript, and these marts must
  match it to the last digit, including on days with negative net revenue.
#}
{% macro round_half_up(expression) -%}
    (case
        when ({{ expression }}) - floor({{ expression }}) >= 0.5 then ceil({{ expression }})
        else floor({{ expression }})
    end)
{%- endmacro %}
