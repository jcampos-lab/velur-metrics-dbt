-- Insights must be requested with time_increment=1. A row that spans several days cannot be
-- placed on a single day, so it fails the build.

select account_id, date_start, date_stop
from {{ source('meta_ads', 'insights') }}
where date_start <> date_stop
