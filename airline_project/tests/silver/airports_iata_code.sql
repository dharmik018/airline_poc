-- IATA codes must be exactly 3 capital letters
{{ config(severity='warn') }}  -- warn first, because some odd codes may exist

select iata_code, airport_name, airport_type  -- failing rows
from {{ ref('airports') }}  -- the silver model
where iata_code not rlike '^[A-Z]{3}$'  -- anything that is not 3 letters