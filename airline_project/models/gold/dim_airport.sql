with silver_airport as (
    select * from {{ ref('airports') }}
),

runway_data as (
    select
        airport_ident, 
        count(*) as total_runways, 
        count(case when is_closed != true then 1 end) as total_active_runways,
        max(length_feet) as longest_runway_feet        
    from {{ ref('runways') }}
    group by airport_ident
)

select 
    cast(xxhash64(sa.airport_ident) as bigint) as airport_key,
    cast(sa.airport_id as int) as airport_id,
    cast(sa.airport_ident as string) as airport_ident,
    cast(sa.iata_code as string) as iata_code,
    cast(sa.icao_code as string) as icao_code,
    cast(sa.airport_name as string) as airport_name,
    cast(sa.airport_type as string) as airport_type,
    cast(sa.has_scheduled_service as boolean) as has_scheduled_service,
    cast(sa.latitude as double) as latitude,
    cast(sa.longitude as double) as longitude,
    cast(sa.country_code as string) as country_code,
    cast(sa.country_name as string) as country_name,
    cast(sa.continent_code as string) as continent_code,
    cast(sa.region_code as string) as region_code,
    cast(sa.region_name as string) as region_name,
    cast(sa.region_local_code as string) as region_local_code,
    cast(coalesce(rw.total_runways, 0) as int) as total_runways,
    cast(coalesce(rw.total_active_runways, 0) as int) as total_active_runways,
    cast(rw.longest_runway_feet as int) as longest_runway_feet,
    rw.airport_ident is not null as has_runway_data,
    current_timestamp()  as gold_loaded_at
from silver_airport as sa
left join runway_data as rw on sa.airport_ident = rw.airport_ident