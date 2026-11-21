{{ config(severity='warn') }}  -- warn only, because history stays forever and one bad fetch would fail the test for good

select fetched_at, count(*) as row_count, count(distinct airport_ident) as airport_count  -- size of each fetch
from {{ ref('fact_weather_live') }}  -- gold live forecast
group by fetched_at  -- one line per Lambda run
having count(*) != 26064 or count(distinct airport_ident) != 362  -- 362 airports x 72 hours