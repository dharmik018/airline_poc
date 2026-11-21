-- coordinates must be real places, and (0, 0) is a placeholder

select iata_code, airport_name, latitude, longitude  -- failing rows
from {{ ref('airports') }}  -- the silver model
where latitude not between -90 and 90  -- impossible latitude
   or longitude not between -180 and 180  -- impossible longitude
   or (latitude = 0 and longitude = 0)  -- placeholder in the middle of the ocean