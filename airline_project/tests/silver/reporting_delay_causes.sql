{{ config(warn_if='>0', error_if='>1000') }}  -- warn on any bad row, fail above 1000

with cause_totals as (  -- add up the five delay causes for each flight
    select
        flight_key,
        flight_date,
        is_arrival_delayed_15,
        arrival_delay_minutes,
        coalesce(carrier_delay_minutes, 0) + coalesce(weather_delay_minutes, 0) + coalesce(nas_delay_minutes, 0)
            + coalesce(security_delay_minutes, 0) + coalesce(late_aircraft_delay_minutes, 0) as cause_total_minutes  -- total of causes
    from {{ ref('flight_reporting') }}  -- the silver model
)

select *  -- failing rows
from cause_totals
where is_arrival_delayed_15  -- causes are only reported for flights 15 or more minutes late
  and arrival_delay_minutes is not null  -- skip cancelled and diverted flights
  and cause_total_minutes <> arrival_delay_minutes  -- the causes should add up to the delay