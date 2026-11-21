with date_list as (  -- one row per day
    select explode(sequence(to_date('2024-01-01'), to_date('2030-12-31'), interval 1 day)) as full_date  -- covers flights, weather and live forecast
)

select
    cast(date_format(full_date, 'yyyyMMdd') as int) as date_key,  -- smart key, like 20261120
    full_date as full_date,  -- the date
    year(full_date) as year,  -- year number
    concat('Q', quarter(full_date)) as quarter_name,  -- Q1 to Q4
    concat(year(full_date), '-Q', quarter(full_date)) as year_quarter,  -- 2026-Q4
    month(full_date) as month,  -- month number
    date_format(full_date, 'MMMM') as month_name,  -- November
    cast(date_format(full_date, 'yyyyMM') as int) as year_month,  -- 202611
    trunc(full_date, 'MM') as month_start_date,  -- first day of the month
    weekofyear(full_date) as week_of_year,  -- ISO week number
    trunc(full_date, 'week') as week_start_date,  -- Monday of that week
    dayofmonth(full_date) as day_of_month,  -- 1 to 31
    weekday(full_date) + 1 as day_of_week,  -- 1 = Monday to 7 = Sunday
    date_format(full_date, 'EEEE') as day_name,  -- Friday
    weekday(full_date) >= 5 as is_weekend,  -- Saturday or Sunday
    case  -- northern hemisphere seasons
        when month(full_date) in (12, 1, 2) then 'winter'
        when month(full_date) in (3, 4, 5) then 'spring'
        when month(full_date) in (6, 7, 8) then 'summer'
        else 'fall'
    end as season,  -- season name
    current_timestamp() as gold_loaded_at  -- lineage column
from date_list  -- all days 