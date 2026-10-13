-- Ad spend per day, summed across ad accounts, on the day the ad platform reports it.

select
    date_local as metric_date,
    cast(sum(spend_cents) as bigint) as spend_cents
from {{ ref('stg_meta_ads__insights') }}
group by date_local
