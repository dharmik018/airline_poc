{{ config(materialized='table') }}

with latest as (
    select *
    from {{ ref('fact_weather_live') }}
    where fetched_at = (select max(fetched_at) from {{ ref('fact_weather_live') }})
      and lead_hours >= 0
),

banded as (
    select
        airport_key,
        date_key,
        airport_ident,
        weather_hour_local,
        fetched_at,
        lead_hours,
        case
            when hour(weather_hour_local) < 6  then 'night'
            when hour(weather_hour_local) < 12 then 'morning'
            when hour(weather_hour_local) < 18 then 'afternoon'
            else 'evening'
        end as part_of_day,
        weather_code,
        temperature_c,
        precipitation_mm,
        wind_gust_kmh,
        {{ precipitation_band('precipitation_mm') }} as precipitation_band,
        {{ wind_gust_band('wind_gust_kmh') }} as wind_gust_band,
        {{ is_freezing('temperature_c') }} as is_freezing
    from latest
)

select
    cast(xxhash64(concat_ws('|', b.airport_ident,
        date_format(b.weather_hour_local, 'yyyy-MM-dd HH:mm'))) as bigint) as prediction_key,
    b.airport_key,
    b.date_key,
    b.airport_ident,
    b.weather_hour_local,
    b.fetched_at,
    b.lead_hours,
    b.part_of_day,
    b.weather_code,
    b.temperature_c,
    b.precipitation_mm,
    b.wind_gust_kmh,
    b.precipitation_band,
    b.wind_gust_band,
    b.is_freezing,

    p.pattern_key,
    p.flight_count as historical_flight_count,
    p.departure_delay_rate as historical_departure_delay_rate,
    p.average_delay_when_delayed_minutes as historical_average_delay_when_delayed_minutes,
    p.cancellation_rate as historical_cancellation_rate,

    case
        when p.pattern_key is null            then 'none'
        when p.operated_flight_count >= 100   then 'high'
        when p.operated_flight_count >= 30    then 'medium'
        else 'low'
    end  as data_confidence,
    case
        when p.departure_delay_rate is null   then 'unknown'
        when p.departure_delay_rate < 0.20    then 'low'
        when p.departure_delay_rate < 0.35    then 'medium'
        else 'high'
    end  as risk_level,

    current_timestamp() as gold_loaded_at
from banded b
left join {{ ref('delay_pattern') }} p
    on  p.origin_airport_key = b.airport_key
    and p.part_of_day        = b.part_of_day
    and p.precipitation_band = b.precipitation_band
    and p.wind_gust_band     = b.wind_gust_band
    and p.is_freezing        = b.is_freezing