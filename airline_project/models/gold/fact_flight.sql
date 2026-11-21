with silver_flight as (  -- silver flights
    select * from {{ ref('flight_reporting') }}  -- one row per flight leg
),

airport_lookup as (  -- IATA code to airport ident
    select airport_code, airport_ident from {{ ref('airport_codes') }}  -- includes the PBI to KPBI fix
)

select
    cast(xxhash64(silver_flight.flight_key) as bigint) as flight_key,  -- surrogate key
    cast(silver_flight.flight_key as string) as source_flight_key,  -- key from silver
    cast(date_format(silver_flight.flight_date, 'yyyyMMdd') as int) as date_key,  -- FK to dim_date
    cast(xxhash64(silver_flight.airline_code) as bigint) as airline_key,  -- FK to dim_airline
    cast(silver_flight.flight_date as date) as flight_date,  -- flight date
    cast(silver_flight.flight_number as string) as flight_number,  -- flight number
    cast(silver_flight.tail_number as string) as tail_number,  -- plane tail number
    cast(silver_flight.origin_airport_code as string) as origin_airport_code,  -- origin IATA code
    case  -- null when the airport is not found, because xxhash64(null) returns 42
        when origin_lookup.airport_ident is null then null
        else cast(xxhash64(origin_lookup.airport_ident) as bigint)
    end as origin_airport_key,  -- FK to dim_airport
    cast(silver_flight.origin_city_name as string) as origin_city_name,  -- origin city
    cast(silver_flight.origin_state_code as string) as origin_state_code,  -- origin state
    cast(silver_flight.destination_airport_code as string) as destination_airport_code,  -- destination IATA code
    case  -- null when the airport is not found
        when destination_lookup.airport_ident is null then null
        else cast(xxhash64(destination_lookup.airport_ident) as bigint)
    end as destination_airport_key,  -- FK to dim_airport
    cast(silver_flight.destination_city_name as string) as destination_city_name,  -- destination city
    cast(silver_flight.destination_state_code as string) as destination_state_code,  -- destination state
    cast(silver_flight.scheduled_departure_at as timestamp_ntz) as scheduled_departure_at,  -- planned departure, local time
    cast(silver_flight.actual_departure_at as timestamp_ntz) as actual_departure_at,  -- real departure, local time
    cast(silver_flight.scheduled_arrival_at as timestamp_ntz) as scheduled_arrival_at,  -- planned arrival, local time
    cast(silver_flight.actual_arrival_at as timestamp_ntz) as actual_arrival_at,  -- real arrival, local time
    cast(hour(silver_flight.scheduled_departure_at) as int) as scheduled_departure_hour,  -- 0 to 23
    case  -- time of day bands
        when hour(silver_flight.scheduled_departure_at) is null then null
        when hour(silver_flight.scheduled_departure_at) < 6 then 'night'
        when hour(silver_flight.scheduled_departure_at) < 12 then 'morning'
        when hour(silver_flight.scheduled_departure_at) < 18 then 'afternoon'
        else 'evening'
    end as part_of_day,  -- night, morning, afternoon or evening
    cast(silver_flight.departure_delay_minutes as int) as departure_delay_minutes,  -- departure delay
    cast(silver_flight.arrival_delay_minutes as int) as arrival_delay_minutes,  -- arrival delay
    cast(silver_flight.is_departure_delayed_15 as boolean) as is_departure_delayed_15,  -- departure 15 minutes or more late
    cast(silver_flight.is_arrival_delayed_15 as boolean) as is_arrival_delayed_15,  -- arrival 15 minutes or more late
    cast(silver_flight.carrier_delay_minutes as int) as carrier_delay_minutes,  -- delay caused by the airline
    cast(silver_flight.weather_delay_minutes as int) as weather_delay_minutes,  -- delay caused by weather
    cast(silver_flight.nas_delay_minutes as int) as nas_delay_minutes,  -- delay caused by air traffic system
    cast(silver_flight.security_delay_minutes as int) as security_delay_minutes,  -- delay caused by security
    cast(silver_flight.late_aircraft_delay_minutes as int) as late_aircraft_delay_minutes,  -- delay caused by a late plane
    cast(
        case  -- late flights where the causes do not add up to the delay
            when silver_flight.arrival_delay_minutes >= 15 then greatest(
                silver_flight.arrival_delay_minutes - (
                    coalesce(silver_flight.carrier_delay_minutes, 0)
                    + coalesce(silver_flight.weather_delay_minutes, 0)
                    + coalesce(silver_flight.nas_delay_minutes, 0)
                    + coalesce(silver_flight.security_delay_minutes, 0)
                    + coalesce(silver_flight.late_aircraft_delay_minutes, 0)
                ), 0)
            else 0
        end as int
    ) as unexplained_delay_minutes,  -- delay with no reported cause
    cast(silver_flight.is_cancelled as boolean) as is_cancelled,  -- flight cancelled
    cast(silver_flight.cancellation_code as string) as cancellation_code,  -- cancel reason code
    cast(silver_flight.is_diverted as boolean) as is_diverted,  -- flight diverted
    cast(silver_flight.taxi_out_minutes as int) as taxi_out_minutes,  -- time from gate to take off
    cast(silver_flight.taxi_in_minutes as int) as taxi_in_minutes,  -- time from landing to gate
    cast(silver_flight.scheduled_elapsed_minutes as int) as scheduled_elapsed_minutes,  -- planned trip time
    cast(silver_flight.is_scheduled_time_bad as boolean) as is_scheduled_time_bad,  -- planned time looks wrong
    cast(silver_flight.actual_elapsed_minutes as int) as actual_elapsed_minutes,  -- real trip time
    cast(silver_flight.air_time_minutes as int) as air_time_minutes,  -- time in the air
    cast(silver_flight.distance_miles as int) as distance_miles,  -- trip distance
    current_timestamp() as gold_loaded_at  -- when this gold model is built
from silver_flight  -- all flights
left join airport_lookup as origin_lookup  -- find origin airport ident
    on silver_flight.origin_airport_code = origin_lookup.airport_code  -- match on IATA code
left join airport_lookup as destination_lookup  -- find destination airport ident
    on silver_flight.destination_airport_code = destination_lookup.airport_code  -- match on IATA code