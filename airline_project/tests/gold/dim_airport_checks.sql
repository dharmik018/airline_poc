select 'row_count_mismatch' as failed_check, cast(null as string) as key_value  -- runway join added or lost rows
from (
    select
        (select count(*) from {{ ref('dim_airport') }}) as gold_count,  -- rows in gold
        (select count(*) from {{ ref('airports') }}) as silver_count  -- rows in silver
)
where gold_count != silver_count  -- must be equal

union all

select 'latitude_out_of_range', airport_ident  -- impossible latitude
from {{ ref('dim_airport') }}  -- gold airports
where latitude not between -90 and 90  -- real earth limits

union all

select 'longitude_out_of_range', airport_ident  -- impossible longitude
from {{ ref('dim_airport') }}  -- gold airports
where longitude not between -180 and 180  -- real earth limits

union all

select 'active_runways_more_than_total', airport_ident  -- active cannot exceed total
from {{ ref('dim_airport') }}  -- gold airports
where total_active_runways > total_runways  -- impossible

union all

select 'runway_flag_mismatch', airport_ident  -- flag does not match the runway count
from {{ ref('dim_airport') }}  -- gold airports
where (has_runway_data = true and total_runways = 0)  -- flag says yes, count says no
   or (has_runway_data = false and total_runways > 0)  -- flag says no, count says yes