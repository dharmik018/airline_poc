with source_airport as (  -- step 1: read the source table
    select * from {{ source('bronze', 'ourairports_airports') }}  -- table named in sources.yml
),

source_countries as (  -- step 1: read the source table
    select * from {{ source('bronze', 'ourairports_countries') }}  -- table named in sources.yml
),

source_regions as (  -- step 1: read the source table
    select * from {{ source('bronze', 'ourairports_regions') }}  -- table named in sources.yml
),

typed_airports as (
    
    select
        try_cast(trim(id) as int) as airport_id,  -- OurAirports row id, used for tie-breaks
        upper(nullif(trim(ident), '')) as airport_ident,  -- OurAirports own code
        upper(nullif(trim(iata_code), '')) as iata_code,  -- 3-letter code used by flights
        upper(nullif(trim(icao_code), '')) as icao_code,  -- 4-letter code
        nullif(trim(name), '') as airport_name,  -- airport name
        nullif(trim(type), '') as airport_type,  -- large, medium, small airport
        case
            when lower(trim(scheduled_service)) = 'yes' then true  -- airlines fly here on a schedule
            when lower(trim(scheduled_service)) = 'no' then false  -- no scheduled flights
            else null  -- unknown value stays visible as null
        end as has_scheduled_service,
        case
            when try_cast(trim(latitude_deg) as double) between -90 and 90 then try_cast(trim(latitude_deg) as double)  -- real latitude kept
            else null  -- impossible or unreadable value becomes null
        end as latitude,  -- needed for weather API
        case
            when try_cast(trim(longitude_deg) as double) between -180 and 180 then try_cast(trim(longitude_deg) as double)  -- real longitude kept
            else null  -- impossible or unreadable value becomes null
        end as longitude,  -- needed for weather API
        upper(nullif(trim(iso_country), '')) as country_code,  -- like US
        upper(nullif(trim(iso_region), '')) as region_code,  -- like US-CA
        try_cast(_loaded_at as timestamp) as bronze_loaded_at  -- when bronze loaded this row
    from source_airport
    where nullif(trim(iata_code), '') is not null  -- flights only use IATA codes
      and lower(trim(type)) <> 'closed'  -- closed airports can share a code
),

typed_countries as (
    select
        upper(trim(code)) as country_code,  -- like US
        nullif(trim(name),'') as country_name, -- full name of country
        upper(nullif(trim(continent),'')) as continent_code  -- like NA
    from source_countries
),

typed_regions as (
    select
        upper(trim(code)) as region_code,  -- like US-CA
        nullif(trim(name),'') as region_name,  -- full name of region
        upper(nullif(trim(local_code),'')) as region_local_code  -- like NA means North America
    from source_regions
)

select
    airports.airport_id,
    airports.airport_ident,
    airports.iata_code,
    airports.icao_code,
    airports.airport_name,
    airports.airport_type,
    airports.has_scheduled_service,
    airports.latitude,
    airports.longitude,
    airports.country_code,
    countries.country_name,
    countries.continent_code,
    airports.region_code,
    regions.region_name,
    regions.region_local_code,
    airports.bronze_loaded_at,  -- timestamp, when bronze loaded the row
    current_timestamp() as silver_loaded_at  -- timestamp, when this silver model is built
from typed_airports as airports
left join typed_countries as countries
    on airports.country_code = countries.country_code
left join typed_regions as regions
    on airports.region_code = regions.region_code