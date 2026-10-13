{#
  A raw money field must be a plain decimal amount with at most two decimals ("49.00", "-5", "0.5").
  Anything else would be silently rounded by the cast in to_cents, so it fails here instead.
#}
{% test is_money_string(model, column_name) %}

select {{ column_name }}
from {{ model }}
where {{ column_name }} is not null
  and not regexp_full_match({{ column_name }}, '-?[0-9]+(\.[0-9]{1,2})?')

{% endtest %}
