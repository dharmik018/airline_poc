-- US airport state from OurAirports must match the state in the flights data
{{ config(severity='warn') }}  -- warn, because territories like Puerto Rico are coded differently

select distinct  -- failing airports
    flights.origin_airport_code,
    flights.origin_state_code as flight_state_code,  -- state in the BTS data
    airports.region_local_code as airport_state_code  -- state in the OurAirports data
from {{ ref('flight_reporting') }} as flights
inner join {{ ref('airport_codes') }} as codes on flights.origin_airport_code = codes.airport_code  -- flight code to airport
inner join {{ ref('airports') }} as airports on codes.airport_ident = airports.airport_ident  -- airport details
where airports.country_code = 'US'  -- states exist only for US airports
  and flights.origin_state_code <> airports.region_local_code  -- the two sources disagree


--warn DCA is VA in BTS and DC in OurAirports, accepted