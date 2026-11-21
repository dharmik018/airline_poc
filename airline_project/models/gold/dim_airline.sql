with silver_airline as (
    select * from {{ ref('airlines') }}
),
seed_airline_name_overrides as (
    select * from {{ ref('airline_name_overrides') }}
)

select 
    cast(xxhash64(sa.iata_code) as bigint) as airline_key,  -- surrogate key for this airline
    cast(sa.airline_id as int) as airline_id,  -- one id per airline
    cast(coalesce(sno.airline_name, sa.airline_name) as string) as airline_name,  -- airline name
    cast(sa.iata_code as string) as iata_code,  -- airline IATA code
    cast(sa.icao_code as string) as icao_code,  -- airline ICAO code
    cast(sa.country_name as string) as country_name,  -- airline home country
    cast(sa.is_active as boolean) as is_active,  -- airline is active
    current_timestamp() as gold_loaded_at  -- when this gold model is built
from silver_airline as sa
left join seed_airline_name_overrides as sno on sa.iata_code = sno.iata_code