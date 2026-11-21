{{ config(warn_if='>0', error_if='>1000') }}  -- warn on any bad row, fail above 1000

select flight_key, flight_date, distance_miles, scheduled_elapsed_minutes, taxi_out_minutes, taxi_in_minutes, air_time_minutes  -- failing rows
from {{ ref('flight_reporting') }}  -- the silver model
where distance_miles <= 0  -- a flight must travel some distance
   or scheduled_elapsed_minutes <= 0  -- planned trip time must be positive
   or taxi_out_minutes < 0  -- time on the ground cannot be negative
   or taxi_in_minutes < 0  -- time on the ground cannot be negative
   or air_time_minutes < 0  -- time in the air cannot be negative