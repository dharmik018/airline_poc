{{ config(warn_if='>0', error_if='>1000') }}  -- warn on any bad row, fail above 1000

select flight_key, flight_date, is_cancelled, cancellation_code  -- every row returned is a failure
from {{ ref('flight_reporting') }}  -- the silver model
where (is_cancelled and cancellation_code is null)  -- cancelled but no reason
   or (not is_cancelled and cancellation_code is not null)  -- not cancelled but has a reason