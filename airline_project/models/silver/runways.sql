with source_runways as (
    select * from {{source('bronze','ourairports_runways')}}
),

typed_runways as (
    select
        try_cast(trim(id) as int) as runway_id,  -- one id per runway
        upper(nullif(trim(airport_ident), '')) as airport_ident,  -- links to silver.airports
        case
            when try_cast(trim(length_ft) as int) > 0 then try_cast(trim(length_ft) as int)  -- real length kept
            else null  -- bad or blank length becomes null
        end as length_feet,  -- runway length
        case
            when trim(closed) = '1' then true  -- runway is closed
            when trim(closed) = '0' then false  -- runway is open
            else null  -- unknown value stays visible
        end as is_closed,
        try_cast(_loaded_at as timestamp) as bronze_loaded_at  -- when bronze loaded this row
    from source_runways
)


select
    runways.runway_id,
    runways.airport_ident,
    runways.length_feet,
    runways.is_closed,
    runways.bronze_loaded_at,  -- timestamp, when bronze loaded the row
    current_timestamp() as silver_loaded_at  -- timestamp, when this silver model is built
from typed_runways as runways
inner join {{ ref('airports') }} as airports on runways.airport_ident = airports.airport_ident