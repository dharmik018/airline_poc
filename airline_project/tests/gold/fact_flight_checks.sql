select 'row_count_mismatch' as failed_check, cast(null as string) as source_flight_key  -- join added or lost rows
from (
    select
        (select count(*) from {{ ref('fact_flight') }}) as gold_count,  -- rows in gold
        (select count(*) from {{ ref('flight_reporting') }}) as silver_count  -- rows in silver
)
where gold_count != silver_count  -- must be equal

union all

select 'departure_flag_mismatch', source_flight_key  -- flag does not match the minutes
from {{ ref('fact_flight') }}  -- gold flights
where (is_departure_delayed_15 = true and departure_delay_minutes < 15)  -- flag yes, minutes no
   or (is_departure_delayed_15 = false and departure_delay_minutes >= 15)  -- flag no, minutes yes

union all

select 'arrival_flag_mismatch', source_flight_key  -- flag does not match the minutes
from {{ ref('fact_flight') }}  -- gold flights
where (is_arrival_delayed_15 = true and arrival_delay_minutes < 15)  -- flag yes, minutes no
   or (is_arrival_delayed_15 = false and arrival_delay_minutes >= 15)  -- flag no, minutes yes

union all

select 'cancelled_but_arrived', source_flight_key  -- cancelled flights cannot arrive
from {{ ref('fact_flight') }}  -- gold flights
where is_cancelled = true and actual_arrival_at is not null  -- impossible

union all

select 'date_mismatch', source_flight_key  -- flight date differs from the planned departure date
from {{ ref('fact_flight') }}  -- gold flights
where scheduled_departure_at is not null  -- only flights with a planned departure
  and cast(scheduled_departure_at as date) != flight_date  -- different day than flight_date
  and not (  -- allow 24:00 flights, which become 00:00 on the next day
        hour(scheduled_departure_at) = 0
        and minute(scheduled_departure_at) = 0
        and cast(scheduled_departure_at as date) = date_add(flight_date, 1)
  )

union all

select 'same_origin_and_destination', source_flight_key  -- a flight must go somewhere
from {{ ref('fact_flight') }}  -- gold flights
where origin_airport_code = destination_airport_code  -- impossible

union all

select 'negative_value', source_flight_key  -- impossible numbers
from {{ ref('fact_flight') }}  -- gold flights
where unexplained_delay_minutes < 0  -- cannot be negative
   or taxi_out_minutes < 0  -- cannot be negative
   or taxi_in_minutes < 0  -- cannot be negative
   or air_time_minutes < 0  -- cannot be negative
   or distance_miles <= 0  -- must be positive