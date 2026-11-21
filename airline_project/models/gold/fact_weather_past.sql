with silver_weather as (  -- silver past weather
    select * from {{ ref('weather') }}  -- one row per airport per hour
)

select
    cast(xxhash64(concat_ws('|', airport_ident, date_format(weather_hour_local, 'yyyy-MM-dd HH:mm'))) as bigint) as weather_hour_key,  -- surrogate key: airport + hour
    cast(airport_ident as string) as airport_ident,  -- natural key
    cast(xxhash64(airport_ident) as bigint) as airport_key,  -- FK to dim_airport
    cast(date_format(weather_hour_local, 'yyyyMMdd') as int) as date_key,  -- FK to dim_date
    cast(weather_hour_local as timestamp_ntz) as weather_hour_local,  -- local hour at the airport
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
    current_timestamp() as gold_loaded_at  -- when this gold model is built
from silver_weather  -- all weather hours