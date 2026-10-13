-- Every metric, every day, must equal what Velur's production engine (TypeScript) computed from
-- the same raw files: same value, same calc_version, no row missing on either side.
-- Returns the rows that disagree; one row fails the build.

with dbt_metrics as (

    select * from {{ ref('metric_snapshots') }}

),

velur_engine as (

    select * from {{ ref('velur_engine_snapshots') }}

)

select
    coalesce(dbt_metrics.metric_id, velur_engine.metric_id) as metric_id,
    coalesce(dbt_metrics.metric_date, velur_engine.metric_date) as metric_date,
    dbt_metrics.value as dbt_value,
    velur_engine.value as velur_value,
    dbt_metrics.calc_version as dbt_calc_version,
    velur_engine.calc_version as velur_calc_version
from dbt_metrics
full outer join velur_engine
    on velur_engine.metric_id = dbt_metrics.metric_id
    and velur_engine.metric_date = dbt_metrics.metric_date
where dbt_metrics.value is distinct from velur_engine.value
   or dbt_metrics.calc_version is distinct from velur_engine.calc_version
