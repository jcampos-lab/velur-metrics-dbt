-- Refunds per store-local day, dated on the day each refund was issued.
-- That is why net revenue can go negative on a quiet day after a busy one.

select
    refund_date_local as metric_date,
    cast(sum(amount_cents) as bigint) as refund_cents
from {{ ref('stg_shopify__refunds') }}
group by refund_date_local
