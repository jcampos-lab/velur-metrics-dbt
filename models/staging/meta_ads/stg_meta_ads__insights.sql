-- One row per ad account per day. Spend is truncated to the cent, never rounded up,
-- and a day Meta reports without a spend field is a zero.

with source as (

    select * from {{ source('meta_ads', 'insights') }}

)

select
    account_id,
    upper(account_currency) as currency,
    cast(date_start as date) as date_local,
    cast(trunc(cast(coalesce(spend, '0') as decimal(18, 6)) * 100) as bigint) as spend_cents,
    cast(coalesce(impressions, '0') as bigint) as impressions,
    cast(coalesce(clicks, '0') as bigint) as clicks
from source
