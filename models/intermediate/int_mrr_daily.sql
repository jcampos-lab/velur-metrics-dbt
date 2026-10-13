-- Monthly recurring revenue at the end of each day: the monthly price of every subscription
-- that had started by that day and had not stopped billing yet.

select
    spine.metric_date,
    cast(coalesce(sum(subscriptions.monthly_price_cents), 0) as bigint) as mrr_cents
from {{ ref('int_date_spine') }} as spine
left join {{ ref('stg_stripe__subscriptions') }} as subscriptions
    on subscriptions.started_date_local <= spine.metric_date
    and (
        subscriptions.canceled_date_local is null
        or subscriptions.canceled_date_local > spine.metric_date
    )
group by spine.metric_date
