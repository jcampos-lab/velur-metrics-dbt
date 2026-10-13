-- Every calendar day in the reporting window, whether or not anything happened on it.
-- A quiet day must be a row with zeros, never a missing row that a chart silently skips.

select cast(day as date) as metric_date
from unnest(
    generate_series(
        cast('{{ var("reporting_start") }}' as date),
        cast('{{ var("reporting_end") }}' as date),
        interval 1 day
    )
) as days(day)
