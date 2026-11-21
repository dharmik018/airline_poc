select distinct weather.weather_code  -- codes in the data
from {{ ref('weather') }} as weather  -- silver weather
left join {{ ref('dim_weather_code') }} as codes on weather.weather_code = codes.weather_code  -- match to the seed
where codes.weather_code is null  -- no match found