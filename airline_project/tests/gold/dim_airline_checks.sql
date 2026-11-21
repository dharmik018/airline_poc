select 'row_count_mismatch' as failed_check, cast(null as string) as key_value  -- join added or lost rows
from (
    select
        (select count(*) from {{ ref('dim_airline') }}) as gold_count,  -- rows in gold
        (select count(*) from {{ ref('airlines') }}) as silver_count  -- rows in silver
)
where gold_count != silver_count  -- must be equal

union all

select 'name_override_not_applied', dim_airline.iata_code  -- fixed name is missing in gold
from {{ ref('dim_airline') }} as dim_airline  -- gold airlines
join {{ ref('airline_name_overrides') }} as seed_airline_name_overrides  -- fixed names
    on dim_airline.iata_code = seed_airline_name_overrides.iata_code  -- match on IATA code
where dim_airline.airline_name != seed_airline_name_overrides.airline_name  -- gold must use the fixed name