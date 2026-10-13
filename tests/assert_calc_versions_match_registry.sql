-- The formula version this project implements for each metric must be the one the registry
-- says is current. A bumped version in the registry fails here until the SQL catches up.

with implemented as (

    select distinct metric_id, calc_version from {{ ref('metric_snapshots') }}

)

select
    coalesce(registry.metric_id, implemented.metric_id) as metric_id,
    registry.calc_version as registry_version,
    implemented.calc_version as implemented_version
from {{ ref('metric_definitions') }} as registry
full outer join implemented on implemented.metric_id = registry.metric_id
where registry.calc_version is distinct from implemented.calc_version
