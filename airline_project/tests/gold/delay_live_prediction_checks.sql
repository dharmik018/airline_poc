-- returns rows only when a check fails

select 'duplicate_airport_hour' as check_name, airport_ident as detail
from {{ ref('delay_live_prediction') }}
group by airport_ident, weather_hour_local
having count(*) > 1

union all
select 'multiple_fetches', cast(count(distinct fetched_at) as string)
from {{ ref('delay_live_prediction') }}
having count(distinct fetched_at) > 1

union all
select 'negative_lead_hours', cast(prediction_key as string)
from {{ ref('delay_live_prediction') }}
where lead_hours < 0

union all
select 'date_key_mismatch', cast(prediction_key as string)
from {{ ref('delay_live_prediction') }}
where date_key <> cast(date_format(weather_hour_local, 'yyyyMMdd') as int)

union all
select 'row_count_mismatch', concat('pred=', p.n, ' source=', s.n)
from (select count(*) as n from {{ ref('delay_live_prediction') }}) p
cross join (
    select count(*) as n
    from {{ ref('fact_weather_live') }}
    where fetched_at = (select max(fetched_at) from {{ ref('fact_weather_live') }})
      and lead_hours >= 0
) s
where p.n <> s.n

union all
select 'match_state_inconsistent', cast(prediction_key as string)
from {{ ref('delay_live_prediction') }}
where (pattern_key is null and (data_confidence <> 'none' or risk_level <> 'unknown'
                                or historical_flight_count is not null))
   or (pattern_key is not null and (data_confidence = 'none'
                                    or historical_flight_count is null))

union all
select 'risk_level_wrong', cast(prediction_key as string)
from {{ ref('delay_live_prediction') }}
where historical_departure_delay_rate is not null
  and risk_level <> case
        when historical_departure_delay_rate < 0.20 then 'low'
        when historical_departure_delay_rate < 0.35 then 'medium'
        else 'high' end

union all
select 'rate_out_of_range', cast(prediction_key as string)
from {{ ref('delay_live_prediction') }}
where historical_departure_delay_rate not between 0 and 1
   or historical_cancellation_rate not between 0 and 1