-- every airline code in flights must find an airline
{{ config(severity='warn') }}  -- warn first, because a few old or renamed codes can exist

select
    flights.airline_code,
    count(*) as flight_count  -- how many flights are affected
from {{ ref('flight_reporting') }} as flights
left join {{ ref('airlines') }} as airlines on flights.airline_code = airlines.iata_code  -- try to match
where airlines.iata_code is null  -- no match found
group by flights.airline_code