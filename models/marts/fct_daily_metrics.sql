-- One row per store-local day with every daily revenue metric.
--
-- gross       line items before discounts, excluding shipping and tax, on the order's day
-- net         gross − discounts (order's day) − refunds (refund's day)
-- AOV         (gross − discounts) ÷ orders, rounded half up to the cent
-- refund rate refunds issued today ÷ gross booked today: a cash-flow view of returns
-- repeat rate orders from returning known customers ÷ all orders (guests only in the denominator)
-- MRR         end-of-day monthly recurring revenue
-- ROAS        net revenue ÷ ad spend, from the day's own data, not the ad platform's attribution
--
-- Ratios are rounded to 4 decimals and are 0 when their denominator is 0.

with spine as (

    select * from {{ ref('int_date_spine') }}

),

orders as (

    select * from {{ ref('int_orders_daily') }}

),

refunds as (

    select * from {{ ref('int_refunds_daily') }}

),

ad_spend as (

    select * from {{ ref('int_ad_spend_daily') }}

),

mrr as (

    select * from {{ ref('int_mrr_daily') }}

),

daily as (

    select
        spine.metric_date,
        coalesce(orders.orders, 0) as orders,
        coalesce(orders.gross_cents, 0) as gross_cents,
        coalesce(orders.discount_cents, 0) as discount_cents,
        coalesce(orders.new_customers, 0) as new_customers,
        coalesce(orders.returning_orders, 0) as returning_orders,
        coalesce(refunds.refund_cents, 0) as refund_cents,
        coalesce(ad_spend.spend_cents, 0) as ad_spend_cents,
        coalesce(mrr.mrr_cents, 0) as mrr_cents
    from spine
    left join orders on orders.metric_date = spine.metric_date
    left join refunds on refunds.metric_date = spine.metric_date
    left join ad_spend on ad_spend.metric_date = spine.metric_date
    left join mrr on mrr.metric_date = spine.metric_date

)

select
    metric_date,
    gross_cents as gross_revenue_cents,
    discount_cents as discounts_cents,
    refund_cents as refunds_cents,
    gross_cents - discount_cents - refund_cents as net_revenue_cents,
    orders,
    case
        when orders = 0 then 0
        -- integer round half up: exact, no floating point
        else (2 * (gross_cents - discount_cents) + orders) // (2 * orders)
    end as aov_cents,
    cast(case
        when gross_cents = 0 then 0
        else {{ round_half_up('refund_cents / gross_cents * 10000') }} / 10000
    end as double) as refund_rate,
    new_customers,
    cast(case
        when orders = 0 then 0
        else {{ round_half_up('returning_orders / orders * 10000') }} / 10000
    end as double) as repeat_customer_rate,
    mrr_cents,
    ad_spend_cents,
    cast(case
        when ad_spend_cents = 0 then 0
        else {{ round_half_up('(gross_cents - discount_cents - refund_cents) / ad_spend_cents * 10000') }} / 10000
    end as double) as blended_roas
from daily
