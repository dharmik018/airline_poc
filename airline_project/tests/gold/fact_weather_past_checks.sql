select 'row_count_mismatch' as failed_check, cast(null as string) as airport_ident  -- rows added or lost
from (
    select
        (select count(*) from {{ ref('fact_weather_past') }}) as gold_count,  -- rows in gold
        (select count(*) from {{ ref('weather') }}) as silver_count  -- rows in silver
)
where gold_count != silver_count  -- must be equal

union all

select 'duplicate_airport_hour', airport_ident  -- same airport and hour twice
from {{ ref('fact_weather_past') }}  -- gold weather
group by airport_ident, weather_hour_local  -- one row expected per group
having count(*) > 1  -- more than one = fail

union all

select 'incomplete_airport_hours', airport_ident  -- an airport with missing hours
from {{ ref('fact_weather_past') }}  -- gold weather
group by airport_ident  -- one line per airport
having count(*) != 18264  -- 761 days x 24 hours

union all

select 'not_on_the_hour', airport_ident  -- weather must be hourly
from {{ ref('fact_weather_past') }}  -- gold weather
where minute(weather_hour_local) != 0  -- minutes must be 00

union all

select 'value_out_of_range', airport_ident  -- impossible values
from {{ ref('fact_weather_past') }}  -- gold weather
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