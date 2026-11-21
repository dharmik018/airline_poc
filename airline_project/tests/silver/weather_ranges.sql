select *  -- rows with impossible values
from {{ ref('weather') }}  -- silver weather
where humidity_percent not between 0 and 100  -- humidity is a percent
   or cloud_cover_percent not between 0 and 100  -- cloud is a percent
   or cloud_cover_low_percent not between 0 and 100  -- low cloud is a percent
   or wind_direction_degrees not between 0 and 360  -- compass degrees
   or precipitation_mm < 0 or rain_mm < 0 or snowfall_cm < 0 or snow_depth_m < 0  -- cannot be negative
   or wind_speed_kmh < 0  -- cannot be negative
   or temperature_c not between -60 and 60  -- outside any real US reading