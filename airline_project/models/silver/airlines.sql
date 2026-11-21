with source_airlines as (
    select * from {{source('bronze','openflights_airlines')}}
)


select 
    try_cast(trim(airline_id) as int) as airline_id,  -- one id per airline
    coalesce(overrides.airline_name, nullif(trim(source_airlines.name), '')) as airline_name,  -- airline name
    upper(trim(iata)) as iata_code,  -- airline IATA code
    upper(nullif(trim(icao),'')) as icao_code,  -- airline ICAO code
    nullif(trim(country),'') as country_name,  -- airline home country
    case 
        when upper(trim(active)) = 'Y' then true -- airline is active
        when upper(trim(active)) = 'N' then false -- airline is inactive
        else null  -- unknown value stays visible
    end as is_active,
    try_cast(_loaded_at as timestamp) as bronze_loaded_at,  -- when bronze loaded this
    current_timestamp() as silver_loaded_at  -- when this silver model is built
from source_airlines
left join {{ ref('airline_name_overrides') }} as overrides on upper(trim(source_airlines.iata)) = overrides.iata_code  -- manual name fixes
where upper(trim(iata)) rlike '^[A-Z0-9]{2}$'  -- only keep valid IATA codes
qualify row_number() over (partition by upper(trim(iata)) order by case when upper(trim(active)) = 'Y' then 0 else 1 end, try_cast(trim(airline_id) as int)) = 1  -- one row per code, active first, then lowest id