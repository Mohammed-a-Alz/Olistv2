with calendar_dates as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2050-12-31' as date)"
    ) }}

),

final as (

    select
        -- primary key
        date_day::date                                          as date_day,

        -- day level
        extract(day from date_day)                             as day_of_month_number,
        extract(dayofyear from date_day)                       as day_of_year_number,
        extract(dayofweek from date_day)                       as day_of_week_number,
        dayname(date_day)                                      as short_weekday_name,
        case extract(dayofweek from date_day)
            when 0 then 'Sunday'
            when 1 then 'Monday'
            when 2 then 'Tuesday'
            when 3 then 'Wednesday'
            when 4 then 'Thursday'
            when 5 then 'Friday'
            when 6 then 'Saturday'
        end                                                    as full_weekday_name,

        -- week level
        extract(week from date_day)                            as week_of_year_number,

        -- month level
        extract(month from date_day)                           as month_of_year_number,
        monthname(date_day)                                    as short_month_name,
        case extract(month from date_day)
            when 1  then 'January'
            when 2  then 'February'
            when 3  then 'March'
            when 4  then 'April'
            when 5  then 'May'
            when 6  then 'June'
            when 7  then 'July'
            when 8  then 'August'
            when 9  then 'September'
            when 10 then 'October'
            when 11 then 'November'
            when 12 then 'December'
        end                                                    as full_month_name,

        -- quarter level
        extract(quarter from date_day)                         as quarter_of_year_number,
        'Q' || extract(quarter from date_day)                  as quarter_name,

        -- year level
        extract(year from date_day)                            as year_number,

        -- combined labels
        to_char(date_day, 'YYYY-MM-DD')                        as full_date_string,
        monthname(date_day) || ' '
            || extract(year from date_day)                     as short_month_year,
        case extract(month from date_day)
            when 1  then 'January'
            when 2  then 'February'
            when 3  then 'March'
            when 4  then 'April'
            when 5  then 'May'
            when 6  then 'June'
            when 7  then 'July'
            when 8  then 'August'
            when 9  then 'September'
            when 10 then 'October'
            when 11 then 'November'
            when 12 then 'December'
        end || ' ' || extract(year from date_day)              as full_month_year,
        to_char(date_day, 'YYYY-MM')                           as year_month,
        'Q' || extract(quarter from date_day) || ' '
            || extract(year from date_day)                     as year_quarter,

        -- booleans
        -- in Snowflake: dayofweek 0=Sunday, 6=Saturday
        case
            when extract(dayofweek from date_day) in (0, 6) then true
            else false
        end                                                    as is_weekend,

        case
            when extract(dayofweek from date_day) in (1, 2, 3, 4, 5) then true
            else false
        end                                                    as is_weekday

    from calendar_dates

)

select * from final