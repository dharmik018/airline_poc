select 'duplicate_forecast_row' as failed_check, airport_ident  -- same airport, hour and fetch twice
from {{ ref('fact_weather_live') }}  -- gold live forecast
group by airport_ident, weather_hour_local, fetched_at  -- one row expected per group
having count(*) > 1  -- more than one = fail

union all

select 'not_on_the_hour', airport_ident  -- forecast must be hourly
from {{ ref('fact_weather_live') }}  -- gold live forecast
where minute(weather_hour_local) != 0  -- minutes must be 00

union all

select 'lead_hours_out_of_range', airport_ident  -- forecast window is local midnight to 72 hours later
from {{ ref('fact_weather_live') }}  -- gold live forecast
where lead_hours not between -30 and 80  -- wider than any real airport time zone gap

union all

select 'fetched_in_the_future', airport_ident  -- a fetch cannot be from the future
from {{ ref('fact_weather_live') }}  -- gold live forecast
where fetched_at > current_timestamp()  -- impossible

union all

select 'value_out_of_range', airport_ident  -- impossible values
from {{ ref('fact_weather_live') }}  -- gold live forecast
where humidity_percent not between 0 and 100  -- percent
   or cloud_cover_percent not between 0 and 100  -- percent
   or cloud_cover_low_percent not between 0 and 100  -- percent
   or wind_direction_degrees not between 0 and 360  -- compass degrees
   or temperature_c not between -90 and 60  -- real earth limits
   or wind_speed_kmh < 0  -- cannot be negative
   or wind_gust_kmh < 0  -- cannot be negative
   or precipitation_mm < 0  -- cannot be negative
   or rain_mm < 0  -- cannot be negative
   or snowfall_cm < 0  -- cannot be negative
   or snow_depth_m < 0  -- cannot be negative
   or rain_mm > precipitation_mm  -- rain is part of all precipitation