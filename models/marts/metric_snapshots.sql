-- The same daily metrics in long format, one row per metric per day, shaped like Velur's own
-- mart.metric_snapshots table.
--
-- Every metric carries the calc_version of the formula this project implements. Changing a
-- formula means bumping its version here; assert_calc_versions_match_registry fails the build
-- until this file and the metric registry (seeds/metric_definitions.csv) agree.

with daily as (

    select
        metric_date,
        cast(gross_revenue_cents as double) as gross_revenue_daily,
        cast(net_revenue_cents as double) as net_revenue_daily,
        cast(orders as double) as orders_daily,
        cast(aov_cents as double) as aov_daily,
        cast(refunds_cents as double) as refund_amount_daily,
        refund_rate as refund_rate_daily,
        cast(new_customers as double) as new_customers_daily,
        repeat_customer_rate as repeat_customer_rate_daily,
        cast(mrr_cents as double) as mrr_eod,
        cast(ad_spend_cents as double) as ad_spend_daily,
        blended_roas as blended_roas_daily,
        cast(discounts_cents as double) as discounts_daily
    from {{ ref('fct_daily_metrics') }}

),

unpivoted as (

    unpivot daily
    on columns(* exclude (metric_date))
    into name metric_id value value

),

implemented_versions (metric_id, calc_version) as (

    values
        ('gross_revenue_daily', 1),
        ('net_revenue_daily', 1),
        ('orders_daily', 1),
        ('aov_daily', 1),
        ('refund_amount_daily', 1),
        ('refund_rate_daily', 1),
        ('new_customers_daily', 1),
        ('repeat_customer_rate_daily', 2),
        ('mrr_eod', 2),
        ('ad_spend_daily', 1),
        ('blended_roas_daily', 1),
        ('discounts_daily', 1)

)

select
    unpivoted.metric_id,
    unpivoted.metric_date,
    unpivoted.value,
    implemented_versions.calc_version
from unpivoted
inner join implemented_versions on implemented_versions.metric_id = unpivoted.metric_id
