{{ config(materialized='table') }}

with eligible as (
    select
        origin_airport_key,
        part_of_day,
        {{ precipitation_band('origin_precipitation_mm') }} as precipitation_band,
        {{ wind_gust_band('origin_wind_gust_kmh') }}        as wind_gust_band,
        {{ is_freezing('origin_temperature_c') }}           as is_freezing,
        flight_date,
        is_cancelled,
        is_diverted,
        is_departure_delayed_15,
        departure_delay_minutes,
        carrier_delay_minutes,
        weather_delay_minutes,
        nas_delay_minutes,
        security_delay_minutes,
        late_aircraft_delay_minutes,
        unexplained_delay_minutes
    from {{ ref('fact_flight_weather') }}
    where has_origin_weather = true
      and origin_airport_key is not null
      and part_of_day is not null
      and origin_precipitation_mm is not null
      and origin_wind_gust_kmh is not null
      and origin_temperature_c is not null
)

select
    cast(xxhash64(concat_ws('|',
        origin_airport_key, part_of_day, precipitation_band,
        wind_gust_band, cast(is_freezing as string))) as bigint) as pattern_key,
    origin_airport_key,
    part_of_day,
    precipitation_band,
    wind_gust_band,
    is_freezing,

    count(*) as flight_count,
    count_if(is_cancelled = false) as operated_flight_count,
    count_if(is_cancelled = true) as cancelled_flight_count,
    count_if(is_diverted = true) as diverted_flight_count,
    count_if(is_cancelled = false and is_departure_delayed_15 = true) as delayed_departure_count,

    round(count_if(is_cancelled = false and is_departure_delayed_15 = true)
          / nullif(count_if(is_cancelled = false), 0), 4) as departure_delay_rate,
    round(avg(case when is_cancelled = false
                   then departure_delay_minutes end), 2) as average_departure_delay_minutes,
    round(avg(case when is_cancelled = false and is_departure_delayed_15 = true
                   then departure_delay_minutes end), 2) as average_delay_when_delayed_minutes,
    round(count_if(is_cancelled = true) / count(*), 4) as cancellation_rate,
    cast(coalesce(sum(carrier_delay_minutes), 0) as bigint) as carrier_delay_minutes_total,
    cast(coalesce(sum(weather_delay_minutes), 0) as bigint) as weather_delay_minutes_total,
    cast(coalesce(sum(nas_delay_minutes), 0) as bigint) as nas_delay_minutes_total,
    cast(coalesce(sum(security_delay_minutes), 0) as bigint) as security_delay_minutes_total,
    cast(coalesce(sum(late_aircraft_delay_minutes), 0) as bigint) as late_aircraft_delay_minutes_total,
    cast(coalesce(sum(unexplained_delay_minutes), 0) as bigint)   as unexplained_delay_minutes_total,

    min(flight_date) as pattern_start_date,
    max(flight_date) as pattern_end_date,
    current_timestamp() as gold_loaded_at
from eligible
group by origin_airport_key, part_of_day, precipitation_band, wind_gust_band, is_freezing