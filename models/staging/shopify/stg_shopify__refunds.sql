-- One row per refund, with its transactions summed. A refund counts on the day it was issued,
-- not on the day of the order it refunds.

with refunds as (

    select * from {{ source('shopify', 'refunds') }}

),

transactions as (

    select
        refund_id,
        cast(sum({{ to_cents('amount') }}) as bigint) as amount_cents
    from {{ source('shopify', 'refund_transactions') }}
    group by refund_id

),

typed as (

    select
        refunds.id as refund_id,
        refunds.order_id,
        cast(refunds.created_at as timestamptz) as refunded_at,
        coalesce(transactions.amount_cents, 0) as amount_cents
    from refunds
    left join transactions on transactions.refund_id = refunds.id

)

select
    refund_id,
    order_id,
    refunded_at,
    {{ local_date('refunded_at') }} as refund_date_local,
    amount_cents
from typed
