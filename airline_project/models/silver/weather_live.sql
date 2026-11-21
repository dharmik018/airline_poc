{{ config(materialized='table') }}  -- rebuild every run, so old rows drop out

with parsed_weather as (  -- step 1: fix types and names
    select
        airport_ident as airport_ident,  -- airport key
        to_timestamp_ntz(time, "yyyy-MM-dd'T'HH:mm") as weather_hour_local,  -- local hour, no timezone
        timezone as timezone_name,  -- local timezone name
        try_cast(elevation as double) as elevation_meters,  -- airport height
        try_cast(temperature_2m as double) as temperature_c,  -- temperature
        try_cast(relative_humidity_2m as double) as humidity_percent,  -- humidity
        try_cast(dew_point_2m as double) as dew_point_c,  -- dew point
        try_cast(precipitation as double) as precipitation_mm,  -- all precipitation
        try_cast(rain as double) as rain_mm,  -- rain only
        try_cast(snowfall as double) as snowfall_cm,  -- new snow
        try_cast(snow_depth as double) as snow_depth_m,  -- snow on the ground
        try_cast(weather_code as int) as weather_code,  -- WMO code
        try_cast(cloud_cover as double) as cloud_cover_percent,  -- total cloud
        try_cast(cloud_cover_low as double) as cloud_cover_low_percent,  -- low cloud
        try_cast(wind_speed_10m as double) as wind_speed_kmh,  -- wind speed
        try_cast(wind_direction_10m as double) as wind_direction_degrees,  -- wind direction
        try_cast(wind_gusts_10m as double) as wind_gust_kmh,  -- wind gust
        to_timestamp(regexp_replace(  -- 2026-11-20T06-39-06Z to a real UTC time
            fetched_at_utc,
            '^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2})-([0-9]{2})-([0-9]{2})Z$',
            '$1T$2:$3:$4Z'
        )) as fetched_at_utc,  -- time Lambda fetched this forecast
        _loaded_at as bronze_loaded_at,  -- lineage from bronze
        current_timestamp() as silver_loaded_at  -- lineage from silver
    from {{ source('bronze', 'weather_live') }}  -- bronze live table, all runs
)

select *  -- keep all columns
from parsed_weather  -- typed rows
where fetched_at_utc >= (select max(fetched_at_utc) from parsed_weather) - interval 7 days  -- keep only the last week