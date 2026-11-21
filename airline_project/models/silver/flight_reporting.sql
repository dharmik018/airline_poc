-- one clean row per flight, built from bronze.reporting_ontime_flights

with source_flights as (  -- step 1: read the raw bronze table
    select * from {{ source('bronze', 'reporting_ontime_flights') }}  -- table named in sources.yml
),

--148 late flights have all causes at 0 in the source (147 zero, 1 blank)

typed_flights as (  -- step 2: fix data types and clean text
    select
        md5(concat_ws('|', trim(FL_DATE), trim(OP_UNIQUE_CARRIER), trim(OP_CARRIER_FL_NUM), trim(ORIGIN), trim(DEST), trim(CRS_DEP_TIME))) as flight_key,  -- one id per flight
        to_date(try_to_timestamp(trim(FL_DATE), 'M/d/yyyy h:mm:ss a')) as flight_date,  -- 8/21/2025 12:00:00 AM becomes a date
        upper(trim(OP_UNIQUE_CARRIER)) as airline_code,  -- airline code like HA
        nullif(trim(OP_CARRIER_FL_NUM), '') as flight_number,  -- flight number as text
        nullif(trim(TAIL_NUM), '') as tail_number,  -- plane id, blank becomes null
        upper(trim(ORIGIN)) as origin_airport_code,  -- departure airport code
        nullif(trim(ORIGIN_CITY_NAME), '') as origin_city_name,  -- departure city like Kona, HI
        upper(nullif(trim(ORIGIN_STATE_ABR), '')) as origin_state_code,  -- departure state like HI
        upper(trim(DEST)) as destination_airport_code,  -- arrival airport code
        nullif(trim(DEST_CITY_NAME), '') as destination_city_name,  -- arrival city
        upper(nullif(trim(DEST_STATE_ABR), '')) as destination_state_code,  -- arrival state
        {{ hhmm_to_minutes('CRS_DEP_TIME') }} as scheduled_departure_minutes,  -- 1750 becomes 1070 minutes after midnight
        {{ hhmm_to_minutes('CRS_ARR_TIME') }} as scheduled_arrival_minutes,  -- same for arrival time
        {{ text_to_int('DEP_DELAY') }} as departure_delay_minutes,  -- negative means early
        {{ text_to_int('ARR_DELAY') }} as arrival_delay_minutes,  -- negative means early
        {{ text_to_flag('DEP_DEL15') }} as is_departure_delayed_15,  -- true if 15 or more minutes late
        {{ text_to_flag('ARR_DEL15') }} as is_arrival_delayed_15,  -- true if 15 or more minutes late
        {{ text_to_int('CARRIER_DELAY') }} as carrier_delay_minutes,  -- null is not zero
        {{ text_to_int('WEATHER_DELAY') }} as weather_delay_minutes,  -- delay caused by weather
        {{ text_to_int('NAS_DELAY') }} as nas_delay_minutes,  -- air traffic system delay
        {{ text_to_int('SECURITY_DELAY') }} as security_delay_minutes,  -- security delay
        {{ text_to_int('LATE_AIRCRAFT_DELAY') }} as late_aircraft_delay_minutes,  -- late plane from earlier flight
        {{ text_to_flag('CANCELLED') }} as is_cancelled,  -- true if cancelled
        nullif(trim(CANCELLATION_CODE), '') as cancellation_code,  -- A carrier, B weather, C air system, D security
        {{ text_to_flag('DIVERTED') }} as is_diverted,  -- true if sent to another airport
        {{ text_to_int('TAXI_OUT') }} as taxi_out_minutes,  -- time from gate to takeoff
        {{ text_to_int('TAXI_IN') }} as taxi_in_minutes,  -- time from landing to gate
        case
            when {{ text_to_int('CRS_ELAPSED_TIME') }} <= 0 then null  -- 14 rows have a negative value, set to null
            else {{ text_to_int('CRS_ELAPSED_TIME') }}  -- good value is kept, 4 blank rows stay null
        end as scheduled_elapsed_minutes,
        coalesce({{ text_to_int('CRS_ELAPSED_TIME') }} <= 0, false) as is_scheduled_time_bad,  -- true only for the 14 bad values
        {{ text_to_int('ACTUAL_ELAPSED_TIME') }} as actual_elapsed_minutes,  -- real trip time
        {{ text_to_int('AIR_TIME') }} as air_time_minutes,  -- time in the air
        {{ text_to_int('DISTANCE') }} as distance_miles,  -- trip distance
        _source_file as source_file,  -- which file this row came from
        try_cast(_loaded_at as timestamp) as bronze_loaded_at,  -- when bronze loaded this row
        current_timestamp() as silver_loaded_at  -- when this silver model is built
    from source_flights
),

scheduled_flights as (  -- step 3: build scheduled timestamps (local airport time)
    select
        *,
        timestampadd(MINUTE, scheduled_departure_minutes, cast(flight_date as timestamp_ntz)) as scheduled_departure_at,  -- date plus minutes
        timestampadd(
            MINUTE,
            scheduled_arrival_minutes + case when scheduled_arrival_minutes < scheduled_departure_minutes then 1440 else 0 end,  -- next day if arrival clock is earlier
            cast(flight_date as timestamp_ntz)
        ) as scheduled_arrival_at  -- scheduled landing time
    from typed_flights
)

select  -- step 4: final columns, actual times, and duplicate removal
    flight_key,
    flight_date,
    airline_code,
    flight_number,
    tail_number,
    origin_airport_code,
    origin_city_name,
    origin_state_code,
    destination_airport_code,
    destination_city_name,
    destination_state_code,
    scheduled_departure_at,
    timestampadd(MINUTE, departure_delay_minutes, scheduled_departure_at) as actual_departure_at,  -- scheduled plus delay
    scheduled_arrival_at,
    timestampadd(MINUTE, arrival_delay_minutes, scheduled_arrival_at) as actual_arrival_at,  -- scheduled plus delay
    departure_delay_minutes,
    arrival_delay_minutes,
    is_departure_delayed_15,
    is_arrival_delayed_15,
    carrier_delay_minutes,
    weather_delay_minutes,
    nas_delay_minutes,
    security_delay_minutes,
    late_aircraft_delay_minutes,
    is_cancelled,
    cancellation_code,
    is_diverted,
    taxi_out_minutes,
    taxi_in_minutes,
    scheduled_elapsed_minutes,
    is_scheduled_time_bad,
    actual_elapsed_minutes,
    air_time_minutes,
    distance_miles,
    source_file,
    bronze_loaded_at,
    silver_loaded_at
from scheduled_flights
qualify row_number() over (partition by flight_key order by bronze_loaded_at desc) = 1  -- keep one row per flight