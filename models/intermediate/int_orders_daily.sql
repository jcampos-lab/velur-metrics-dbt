-- Order totals per store-local day.
--
-- A returning order is one placed by a known customer whose first-ever order was before today.
-- A customer who places their first order and a second one on the same day is new, not returning,
-- and a guest is in the order count but never new and never returning.

with orders as (

    select * from {{ ref('stg_shopify__orders') }}

),

flagged as (

    select
        *,
        customer_ref is not null
            and not bool_or(is_first_order) over (
                partition by order_date_local, customer_ref
            ) as is_returning
    from orders

)

select
    order_date_local as metric_date,
    cast(count(*) as bigint) as orders,
    cast(sum(gross_cents) as bigint) as gross_cents,
    cast(sum(discount_cents) as bigint) as discount_cents,
    cast(count(*) filter (where is_first_order) as bigint) as new_customers,
    cast(count(*) filter (where is_returning) as bigint) as returning_orders
from flagged
group by order_date_local
