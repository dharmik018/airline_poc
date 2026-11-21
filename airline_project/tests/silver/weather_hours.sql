select airport_ident, count(*) as hour_count, count(distinct weather_hour_local) as distinct_hours  -- count hours per airport
from {{ ref('weather') }}  -- silver weather
group by airport_ident  -- one group per airport
having count(*) != 18264 or count(distinct weather_hour_local) != 18264