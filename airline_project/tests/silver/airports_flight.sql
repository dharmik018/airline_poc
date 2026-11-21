-- every origin and destination in flights must find an airport
{{ config(severity='warn') }}  -- warn first, because a few new or renamed codes can exist

with flight_airport_codes as (  -- step 1: all airport codes used by flights
    select origin_airport_code as airport_code, 'origin' as code_role from {{ ref('flight_reporting') }}  -- departure codes
    union all
    select destination_airport_code as airport_code, 'destination' as code_role from {{ ref('flight_reporting') }}  -- arrival codes
)

select  -- step 2: codes with no matching airport
    flight_airport_codes.airport_code,
    flight_airport_codes.code_role,
    count(*) as flight_count  -- how many flights are affected
from flight_airport_codes
left join {{ ref('airport_codes') }} as codes on flight_airport_codes.airport_code = codes.airport_code  -- try to match the code
where codes.airport_code is null  -- no match found
group by flight_airport_codes.airport_code, flight_airport_codes.code_role