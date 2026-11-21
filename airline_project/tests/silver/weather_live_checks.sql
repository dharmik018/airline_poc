select 'duplicate_row' as failed_check, airport_ident, weather_hour_local, fetched_at_utc  -- same airport, hour and fetch twice
from {{ ref('weather_live') }}  -- silver live table
group by airport_ident, weather_hour_local, fetched_at_utc  -- one row expected per group
having count(*) > 1  -- more than one = fail

union all

select 'incomplete_fetch', cast(null as string), cast(null as timestamp_ntz), fetched_at_utc  -- a fetch with missing rows
from {{ ref('weather_live') }}  -- silver live table
group by fetched_at_utc  -- one line per Lambda run
having count(*) != 26064 or count(distinct airport_ident) != 362  -- 362 airports x 72 hours

union all

select 'value_out_of_range', airport_ident, weather_hour_local, fetched_at_utc  -- impossible values
from {{ ref('weather_live') }}  -- silver live table
where humidity_percent not between 0 and 100  -- humidity is a percent
   or cloud_cover_percent not between 0 and 100  -- cloud is a percent
   or cloud_cover_low_percent not between 0 and 100  -- low cloud is a percent
   or wind_direction_degrees not between 0 and 360  -- compass degrees
   or temperature_c not between -90 and 60  -- real earth limits
   or wind_speed_kmh < 0  -- cannot be negative
   or wind_gust_kmh < 0  -- cannot be negative
   or precipitation_mm < 0  -- cannot be negative

union all

select 'more_than_one_week', cast(null as string), cast(null as timestamp_ntz), max(fetched_at_utc)  -- silver keeps too much
from {{ ref('weather_live') }}  -- silver live table
having max(fetched_at_utc) > min(fetched_at_utc) + interval 7 days  -- more than 7 days kept

union all

select 'missing_value', airport_ident, weather_hour_local, fetched_at_utc  -- a cast failed silently
from {{ ref('weather_live') }}  -- silver live table
where humidity_percent is null or dew_point_c is null or precipitation_mm is null  -- any of the 13 values missing
   or rain_mm is null or snowfall_cm is null or snow_depth_m is null
   or cloud_cover_percent is null or cloud_cover_low_percent is null
   or wind_speed_kmh is null or wind_direction_degrees is null or wind_gust_kmh is null