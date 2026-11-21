{{ config(
    materialized='incremental',
    unique_key='weather_live_key',
    incremental_strategy='merge',
    full_refresh=false
) }}  -- add new fetches only, keep old ones, and block --full-refresh because silver has only 7 days

with silver_weather_live as (  -- silver live forecast
    select * from {{ ref('weather_live') }}  -- last 7 days of fetches
    {% if is_incremental() %}
    where fetched_at_utc >= (select max(fetched_at) from {{ this }})  -- only new fetches, plus the newest one again in case it was partly loaded
    {% endif %}
)

select
    cast(xxhash64(concat_ws('|', airport_ident, date_format(weather_hour_local, 'yyyy-MM-dd HH:mm'), cast(unix_micros(fetched_at_utc) as string))) as bigint) as weather_live_key,  -- surrogate key: airport + hour + fetch
    cast(xxhash64(airport_ident) as bigint) as airport_key,  -- FK to dim_airport
    cast(date_format(weather_hour_local, 'yyyyMMdd') as int) as date_key,  -- FK to dim_date, date of the forecast hour
    cast(airport_ident as string) as airport_ident,  -- natural key
    cast(weather_hour_local as timestamp_ntz) as weather_hour_local,  -- forecast hour, local time
    cast(fetched_at_utc as timestamp) as fetched_at,  -- when the forecast was fetched
    cast(timestampdiff(  -- hours from the fetch hour to the forecast hour, both in UTC
        hour,
        date_trunc('hour', convert_timezone('UTC', fetched_at_utc)),
        convert_timezone(timezone_name, 'UTC', weather_hour_local)
    ) as int) as lead_hours,  -- 0 = fetch hour, negative = hour already passed
    cast(timezone_name as string) as timezone_name,  -- local timezone name
    cast(elevation_meters as double) as elevation_meters,  -- airport height
    cast(temperature_c as double) as temperature_c,  -- temperature
    cast(humidity_percent as double) as humidity_percent,  -- humidity
    cast(dew_point_c as double) as dew_point_c,  -- dew point
    cast(precipitation_mm as double) as precipitation_mm,  -- all precipitation
    cast(rain_mm as double) as rain_mm,  -- rain only
    cast(snowfall_cm as double) as snowfall_cm,  -- new snow
    cast(snow_depth_m as double) as snow_depth_m,  -- snow on the ground
    cast(weather_code as int) as weather_code,  -- FK to dim_weather_code
    cast(cloud_cover_percent as double) as cloud_cover_percent,  -- total cloud
    cast(cloud_cover_low_percent as double) as cloud_cover_low_percent,  -- low cloud
    cast(wind_speed_kmh as double) as wind_speed_kmh,  -- wind speed
    cast(wind_direction_degrees as double) as wind_direction_degrees,  -- wind direction
    cast(wind_gust_kmh as double) as wind_gust_kmh,  -- wind gust
    current_timestamp() as gold_loaded_at  -- when this row was built
from silver_weather_live  -- forecast rows