with flight as (  -- gold flights
    select
        *,  -- all flight columns
        cast(date_trunc('hour', scheduled_departure_at) as timestamp_ntz) as departure_hour_local,  -- planned departure, rounded down to the hour
        cast(date_trunc('hour', scheduled_arrival_at) as timestamp_ntz) as arrival_hour_local  -- planned arrival, rounded down to the hour
    from {{ ref('fact_flight') }}  -- one row per flight leg
),

past_weather as (  -- gold past weather
    select * from {{ ref('fact_weather_past') }}  -- one row per airport per hour
),

weather_code as (  -- weather code meanings
    select * from {{ ref('dim_weather_code') }}  -- 28 WMO codes
)

select
    flight.flight_key as flight_key,  -- PK, same key as fact_flight
    flight.source_flight_key as source_flight_key,  -- key from silver
    flight.date_key as date_key,  -- FK to dim_date
    flight.airline_key as airline_key,  -- FK to dim_airline
    flight.origin_airport_key as origin_airport_key,  -- FK to dim_airport
    flight.destination_airport_key as destination_airport_key,  -- FK to dim_airport
    origin_weather.weather_hour_key as origin_weather_hour_key,  -- FK to fact_weather_past, null when no weather
    destination_weather.weather_hour_key as destination_weather_hour_key,  -- FK to fact_weather_past, null when no weather
    flight.flight_date as flight_date,  -- flight date
    flight.flight_number as flight_number,  -- flight number
    flight.tail_number as tail_number,  -- plane tail number
    flight.origin_airport_code as origin_airport_code,  -- origin IATA code
    flight.origin_city_name as origin_city_name,  -- origin city
    flight.origin_state_code as origin_state_code,  -- origin state
    flight.destination_airport_code as destination_airport_code,  -- destination IATA code
    flight.destination_city_name as destination_city_name,  -- destination city
    flight.destination_state_code as destination_state_code,  -- destination state
    flight.scheduled_departure_at as scheduled_departure_at,  -- planned departure
    flight.actual_departure_at as actual_departure_at,  -- real departure
    flight.scheduled_arrival_at as scheduled_arrival_at,  -- planned arrival
    flight.actual_arrival_at as actual_arrival_at,  -- real arrival
    flight.scheduled_departure_hour as scheduled_departure_hour,  -- 0 to 23
    flight.part_of_day as part_of_day,  -- night, morning, afternoon or evening
    flight.departure_delay_minutes as departure_delay_minutes,  -- departure delay
    flight.arrival_delay_minutes as arrival_delay_minutes,  -- arrival delay
    flight.is_departure_delayed_15 as is_departure_delayed_15,  -- departure 15 minutes or more late
    flight.is_arrival_delayed_15 as is_arrival_delayed_15,  -- arrival 15 minutes or more late
    flight.carrier_delay_minutes as carrier_delay_minutes,  -- delay caused by the airline
    flight.weather_delay_minutes as weather_delay_minutes,  -- delay caused by weather
    flight.nas_delay_minutes as nas_delay_minutes,  -- delay caused by air traffic system
    flight.security_delay_minutes as security_delay_minutes,  -- delay caused by security
    flight.late_aircraft_delay_minutes as late_aircraft_delay_minutes,  -- delay caused by a late plane
    flight.unexplained_delay_minutes as unexplained_delay_minutes,  -- delay with no reported cause
    flight.is_cancelled as is_cancelled,  -- flight cancelled
    flight.cancellation_code as cancellation_code,  -- cancel reason code
    flight.is_diverted as is_diverted,  -- flight diverted
    flight.taxi_out_minutes as taxi_out_minutes,  -- time from gate to take off
    flight.taxi_in_minutes as taxi_in_minutes,  -- time from landing to gate
    flight.scheduled_elapsed_minutes as scheduled_elapsed_minutes,  -- planned trip time
    flight.is_scheduled_time_bad as is_scheduled_time_bad,  -- planned time looks wrong
    flight.actual_elapsed_minutes as actual_elapsed_minutes,  -- real trip time
    flight.air_time_minutes as air_time_minutes,  -- time in the air
    flight.distance_miles as distance_miles,  -- trip distance
    origin_weather.weather_hour_local as origin_weather_hour_local,  -- weather hour used at origin
    origin_weather.temperature_c as origin_temperature_c,  -- origin temperature
    origin_weather.humidity_percent as origin_humidity_percent,  -- origin humidity
    origin_weather.dew_point_c as origin_dew_point_c,  -- origin dew point
    origin_weather.precipitation_mm as origin_precipitation_mm,  -- origin all precipitation
    origin_weather.rain_mm as origin_rain_mm,  -- origin rain only
    origin_weather.snowfall_cm as origin_snowfall_cm,  -- origin new snow
    origin_weather.snow_depth_m as origin_snow_depth_m,  -- origin snow on the ground
    origin_weather.weather_code as origin_weather_code,  -- FK to dim_weather_code
    origin_weather.cloud_cover_percent as origin_cloud_cover_percent,  -- origin total cloud
    origin_weather.cloud_cover_low_percent as origin_cloud_cover_low_percent,  -- origin low cloud
    origin_weather.wind_speed_kmh as origin_wind_speed_kmh,  -- origin wind speed
    origin_weather.wind_direction_degrees as origin_wind_direction_degrees,  -- origin wind direction
    origin_weather.wind_gust_kmh as origin_wind_gust_kmh,  -- origin wind gust
    origin_code.condition_group as origin_condition_group,  -- origin weather group
    origin_code.description as origin_condition_description,  -- origin weather text
    origin_code.severity_level as origin_severity_level,  -- origin severity 0 to 3
    destination_weather.weather_hour_local as destination_weather_hour_local,  -- weather hour used at destination
    destination_weather.temperature_c as destination_temperature_c,  -- destination temperature
    destination_weather.humidity_percent as destination_humidity_percent,  -- destination humidity
    destination_weather.dew_point_c as destination_dew_point_c,  -- destination dew point
    destination_weather.precipitation_mm as destination_precipitation_mm,  -- destination all precipitation
    destination_weather.rain_mm as destination_rain_mm,  -- destination rain only
    destination_weather.snowfall_cm as destination_snowfall_cm,  -- destination new snow
    destination_weather.snow_depth_m as destination_snow_depth_m,  -- destination snow on the ground
    destination_weather.weather_code as destination_weather_code,  -- FK to dim_weather_code
    destination_weather.cloud_cover_percent as destination_cloud_cover_percent,  -- destination total cloud
    destination_weather.cloud_cover_low_percent as destination_cloud_cover_low_percent,  -- destination low cloud
    destination_weather.wind_speed_kmh as destination_wind_speed_kmh,  -- destination wind speed
    destination_weather.wind_direction_degrees as destination_wind_direction_degrees,  -- destination wind direction
    destination_weather.wind_gust_kmh as destination_wind_gust_kmh,  -- destination wind gust
    destination_code.condition_group as destination_condition_group,  -- destination weather group
    destination_code.description as destination_condition_description,  -- destination weather text
    destination_code.severity_level as destination_severity_level,  -- destination severity 0 to 3
    origin_weather.weather_hour_key is not null as has_origin_weather,  -- true when origin weather was found
    destination_weather.weather_hour_key is not null as has_destination_weather,  -- true when destination weather was found
    current_timestamp() as gold_loaded_at  -- when this gold model is built
from flight  -- all flights
left join past_weather as origin_weather  -- weather at the origin
    on flight.origin_airport_key = origin_weather.airport_key  -- same airport
    and flight.departure_hour_local = origin_weather.weather_hour_local  -- same local hour
left join past_weather as destination_weather  -- weather at the destination
    on flight.destination_airport_key = destination_weather.airport_key  -- same airport
    and flight.arrival_hour_local = destination_weather.weather_hour_local  -- same local hour
left join weather_code as origin_code  -- origin weather meaning
    on origin_weather.weather_code = origin_code.weather_code  -- match on code
left join weather_code as destination_code  -- destination weather meaning
    on destination_weather.weather_code = destination_code.weather_code  -- match on code