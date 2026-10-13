-- One row per subscription that was ever billed, with its monthly price and the store-local days
-- billing started and stopped.
--
-- Two rules decide MRR:
-- 1. trialing, incomplete and incomplete_expired subscriptions were never billed, so they never count.
-- 2. A cancellation scheduled for the end of the paid period stops billing at current_period_end,
--    not on the day the customer asked to cancel.

with subscriptions as (

    select * from {{ source('stripe', 'subscriptions') }}

),

items as (

    select
        subscription_id,
        cast(sum(cast(unit_amount as bigint) * cast(quantity as bigint)) as bigint) as monthly_price_cents,
        max(cast(current_period_end as bigint)) as current_period_end
    from {{ source('stripe', 'subscription_items') }}
    group by subscription_id

),

billed as (

    select
        subscriptions.id as subscription_id,
        subscriptions.customer as source_customer_id,
        upper(subscriptions.currency) as currency,
        subscriptions.status,
        coalesce(items.monthly_price_cents, 0) as monthly_price_cents,
        to_timestamp(cast(subscriptions.start_date as bigint)) as started_at,
        case
            when cast(subscriptions.cancel_at_period_end as boolean)
                then to_timestamp(items.current_period_end)
            else to_timestamp(cast(subscriptions.canceled_at as bigint))
        end as billing_ends_at
    from subscriptions
    left join items on items.subscription_id = subscriptions.id
    where subscriptions.status not in ('trialing', 'incomplete', 'incomplete_expired')

)

select
    subscription_id,
    {{ pseudonymize('source_customer_id') }} as customer_ref,
    monthly_price_cents,
    currency,
    status,
    {{ local_date('started_at') }} as started_date_local,
    -- active on day D when started_date_local <= D and (this is null or it is after D)
    case when billing_ends_at is not null then {{ local_date('billing_ends_at') }} end as canceled_date_local
from billed
