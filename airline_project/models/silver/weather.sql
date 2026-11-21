select
    upper(trim(airport_ident)) as airport_ident,  -- airport code, for example KJFK
    try_cast(`time` as timestamp_ntz) as weather_hour_local,  -- local hour of the airport
    timezone as timezone_name,  -- local timezone name
    try_cast(elevation as double) as elevation_meters,  -- height of the weather grid point in meters
    try_cast(temperature_2m as double) as temperature_c,  -- temperature in degrees C
    try_cast(relative_humidity_2m as double) as humidity_percent,  -- relative humidity in %
    try_cast(dew_point_2m as double) as dew_point_c,  -- dew point in degrees C
    try_cast(precipitation as double) as precipitation_mm,  -- all precipitation in mm
    try_cast(rain as double) as rain_mm,  -- rain in mm
    try_cast(snowfall as double) as snowfall_cm,  -- snowfall in cm
    try_cast(snow_depth as double) as snow_depth_m,  -- snow depth in m
    try_cast(weather_code as int) as weather_code,  -- WMO weather code
    try_cast(cloud_cover as double) as cloud_cover_percent,  -- total cloud in %
    try_cast(cloud_cover_low as double) as cloud_cover_low_percent,  -- low cloud in %
    try_cast(wind_speed_10m as double) as wind_speed_kmh,  -- wind speed in km/h
    try_cast(wind_direction_10m as double) as wind_direction_degrees,  -- wind direction in degrees
    try_cast(wind_gusts_10m as double) as wind_gust_kmh,  -- wind gust in km/h
    try_cast(_loaded_at as timestamp) as bronze_loaded_at,  -- when bronze loaded it
    current_timestamp() as silver_loaded_at  -- when silver built it
from {{ source('bronze', 'weather') }}  -- bronze weather table