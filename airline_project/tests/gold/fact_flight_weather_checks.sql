select 'row_count_mismatch' as failed_check, cast(null as string) as source_flight_key  -- weather join added or lost flights
from (
    select
        (select count(*) from {{ ref('fact_flight_weather') }}) as weather_count,  -- rows here
        (select count(*) from {{ ref('fact_flight') }}) as flight_count  -- rows in fact_flight
)
where weather_count != flight_count  -- must be equal

union all

select 'origin_flag_mismatch', source_flight_key  -- flag does not match the key
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_origin_weather != (origin_weather_hour_key is not null)  -- must agree

union all

select 'destination_flag_mismatch', source_flight_key  -- flag does not match the key
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_destination_weather != (destination_weather_hour_key is not null)  -- must agree

union all

select 'origin_wrong_hour', source_flight_key  -- weather hour is not the planned departure hour
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_origin_weather = true  -- only rows that found weather
  and origin_weather_hour_local != date_trunc('hour', scheduled_departure_at)  -- must be the same hour

union all

select 'destination_wrong_hour', source_flight_key  -- weather hour is not the planned arrival hour
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_destination_weather = true  -- only rows that found weather
  and destination_weather_hour_local != date_trunc('hour', scheduled_arrival_at)  -- must be the same hour

union all

select 'missing_condition_group', source_flight_key  -- weather found but the code has no meaning
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where (has_origin_weather = true and origin_condition_group is null)  -- origin code not in the seed
   or (has_destination_weather = true and destination_condition_group is null)  -- destination code not in the seed