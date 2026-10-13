-- One row per Shopify order. Money becomes integer cents, the timestamp becomes the store's
-- calendar day, and the customer id is replaced by a pseudonym before anything downstream sees it.

with source as (

    select * from {{ source('shopify', 'orders') }}

),

typed as (

    select
        id as order_id,
        -- processed_at is the business time when an order is backdated; created_at otherwise
        cast(coalesce(processed_at, created_at) as timestamptz) as ordered_at,
        customer_id as source_customer_id,
        upper(currency) as currency,
        {{ to_cents('subtotal_price') }} as subtotal_cents,
        {{ to_cents('total_discounts') }} as discount_cents,
        {{ to_cents("coalesce(total_shipping, '0')") }} as shipping_cents,
        {{ to_cents("coalesce(total_tax, '0')") }} as tax_cents
    from source

),

pseudonymized as (

    select
        * exclude (source_customer_id),
        case
            when source_customer_id is not null then {{ pseudonymize('source_customer_id') }}
        end as customer_ref
    from typed

)

select
    order_id,
    ordered_at,
    {{ local_date('ordered_at') }} as order_date_local,
    customer_ref,
    -- Shopify's subtotal is after discounts; gross revenue is before them
    subtotal_cents + discount_cents as gross_cents,
    discount_cents,
    shipping_cents,
    tax_cents,
    currency,
    -- a guest checkout has no identity, so it is never anyone's first order
    customer_ref is not null
        and ordered_at = min(ordered_at) over (partition by customer_ref) as is_first_order
from pseudonymized
