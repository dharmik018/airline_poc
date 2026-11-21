-- returns rows only when a check fails

select 'duplicate_grain' as check_name, cast(count(*) as string) as detail
from {{ ref('delay_pattern') }}
group by origin_airport_key, part_of_day, precipitation_band, wind_gust_band, is_freezing
having count(*) > 1

union all
select 'flight_count_mismatch', concat('pattern=', p.total, ' fact=', f.total)
from (select sum(flight_count) as total from {{ ref('delay_pattern') }}) p
cross join (
    select count(*) as total
    from {{ ref('fact_flight_weather') }}
    where has_origin_weather = true
      and origin_airport_key is not null
      and part_of_day is not null
      and origin_precipitation_mm is not null
      and origin_wind_gust_kmh is not null
      and origin_temperature_c is not null
) f
where p.total <> f.total

union all
select 'count_logic_error', cast(pattern_key as string)
from {{ ref('delay_pattern') }}
where flight_count <= 0
   or operated_flight_count + cancelled_flight_count <> flight_count
   or delayed_departure_count > operated_flight_count
   or diverted_flight_count > flight_count

union all
select 'rate_out_of_range', cast(pattern_key as string)
from {{ ref('delay_pattern') }}
where departure_delay_rate not between 0 and 1
   or cancellation_rate not between 0 and 1

union all
select 'negative_cause_total', cast(pattern_key as string)
from {{ ref('delay_pattern') }}
where carrier_delay_minutes_total < 0
   or weather_delay_minutes_total < 0
   or nas_delay_minutes_total < 0
   or security_delay_minutes_total < 0
   or late_aircraft_delay_minutes_total < 0
   or unexplained_delay_minutes_total < 0

union all
select 'date_range_reversed', cast(pattern_key as string)
from {{ ref('delay_pattern') }}
where pattern_start_date > pattern_end_date

union all
select 'avg_delay_below_15', cast(pattern_key as string)
from {{ ref('delay_pattern') }}
where delayed_departure_count > 0
  and average_delay_when_delayed_minutes < 15