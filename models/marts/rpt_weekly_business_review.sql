-- One row per Monday-to-Sunday week: the table a Weekly Business Review starts from.
--
-- Ratios are recomputed from the week's own sums. Averaging seven daily refund rates would weight
-- a quiet Sunday the same as a promo Monday, so it is never done here.
-- A week-over-week change is only shown between two complete weeks, and only against a positive
-- base: three days against seven is not a change, and a percentage against a zero or negative
-- week reads as nonsense (a -16,629% "change"), so both stay null.

with daily as (

    select * from {{ ref('fct_daily_metrics') }}

),

weekly as (

    select
        cast(date_trunc('week', metric_date) as date) as week_start,
        count(*) as days_in_week,
        cast(sum(gross_revenue_cents) as bigint) as gross_revenue_cents,
        cast(sum(discounts_cents) as bigint) as discounts_cents,
        cast(sum(refunds_cents) as bigint) as refunds_cents,
        cast(sum(net_revenue_cents) as bigint) as net_revenue_cents,
        cast(sum(orders) as bigint) as orders,
        cast(sum(new_customers) as bigint) as new_customers,
        arg_max(mrr_cents, metric_date) as mrr_end_of_week_cents,
        cast(sum(ad_spend_cents) as bigint) as ad_spend_cents
    from daily
    group by 1

),

with_ratios as (

    select
        *,
        case when orders > 0 then round((gross_revenue_cents - discounts_cents) / orders) end as aov_cents,
        case when gross_revenue_cents > 0 then round(refunds_cents / gross_revenue_cents, 4) end as refund_rate,
        case when ad_spend_cents > 0 then round(net_revenue_cents / ad_spend_cents, 2) end as blended_roas,
        days_in_week = 7 and lag(days_in_week) over (order by week_start) = 7 as is_comparable,
        lag(net_revenue_cents) over (order by week_start) as prior_net_revenue_cents,
        lag(orders) over (order by week_start) as prior_orders
    from weekly

)

select
    week_start,
    week_start + 6 as week_end,
    days_in_week = 7 as is_complete_week,
    gross_revenue_cents,
    discounts_cents,
    refunds_cents,
    net_revenue_cents,
    orders,
    aov_cents,
    refund_rate,
    new_customers,
    mrr_end_of_week_cents,
    ad_spend_cents,
    blended_roas,
    case
        when is_comparable and prior_net_revenue_cents > 0
            then round(net_revenue_cents / prior_net_revenue_cents - 1, 4)
    end as net_revenue_wow_change,
    case
        when is_comparable and prior_orders > 0 then round(orders / prior_orders - 1, 4)
    end as orders_wow_change
from with_ratios
