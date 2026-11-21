-- every airport code that flights can use, mapped to one airport

select
    iata_code as airport_code,  -- official code from OurAirports
    airport_ident  -- the airport this code belongs to
from {{ ref('airports') }}  -- silver airports

union  -- removes exact repeats

select
    upper(trim(flight_airport_code)) as airport_code,  -- extra code used by BTS flights
    upper(trim(ourairports_ident)) as airport_ident  -- the airport this code belongs to
from {{ ref('airport_code_overrides') }}  -- manual list