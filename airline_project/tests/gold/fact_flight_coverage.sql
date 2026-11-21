{{ config(severity='warn') }}  -- warn only, missing weather can be real data gaps

select 'origin_weather_missing' as failed_check, source_flight_key  -- flight inside the weather dates but no origin weather
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_origin_weather = false  -- no weather found
  and scheduled_departure_at >= '2024-08-01' and scheduled_departure_at < '2026-09-01'  -- weather covers these dates

union all

select 'destination_weather_missing', source_flight_key  -- flight inside the weather dates but no destination weather
from {{ ref('fact_flight_weather') }}  -- gold flights with weather
where has_destination_weather = false  -- no weather found
  and scheduled_arrival_at >= '2024-08-01' and scheduled_arrival_at < '2026-09-01'  -- weather covers these dates