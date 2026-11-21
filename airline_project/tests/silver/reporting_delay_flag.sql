{{ config(warn_if='>0', error_if='>1000') }}  -- warn on any bad row, fail above 1000

select flight_key, flight_date, departure_delay_minutes, is_departure_delayed_15, arrival_delay_minutes, is_arrival_delayed_15  -- failing rows
from {{ ref('flight_reporting') }}  -- the silver model
where (departure_delay_minutes is not null and not (is_departure_delayed_15 <=> (departure_delay_minutes >= 15)))  -- departure flag disagrees with minutes
   or (arrival_delay_minutes is not null and not (is_arrival_delayed_15 <=> (arrival_delay_minutes >= 15)))  -- arrival flag disagrees with minutes