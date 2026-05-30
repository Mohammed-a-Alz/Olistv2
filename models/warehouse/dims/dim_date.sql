with calendar_dates as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2050-12-31' as date)"
    ) }}

),

final as (

    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['date(date_day)']) }} as date_sk,

        -- primary key
        date_day::date                                          as date_day,

        -- day level
        extract(day from date_day)                             as day_of_month_number,
        extract(doy from date_day)                             as day_of_year_number,
        extract(isodow from date_day)                          as day_of_week_number,
        to_char(date_day, 'Dy')                                as short_weekday_name,
        to_char(date_day, 'Day')                               as full_weekday_name,

        -- week level
        extract(week from date_day)                            as week_of_year_number,

        -- month level
        extract(month from date_day)                           as month_of_year_number,
        to_char(date_day, 'Mon')                               as short_month_name,
        to_char(date_day, 'Month')                             as full_month_name,

        -- quarter level
        extract(quarter from date_day)                         as quarter_of_year_number,
        'Q' || extract(quarter from date_day)                  as quarter_name,

        -- year level
        extract(year from date_day)                            as year_number,

        -- combined labels (useful for BI tool axis labels)
        to_char(date_day, 'YYYY-MM-DD')                        as full_date_string,
        to_char(date_day, 'Mon') || ' '
            || extract(year from date_day)                     as short_month_year,
        to_char(date_day, 'Month') || ' '
            || extract(year from date_day)                     as full_month_year,
        to_char(date_day, 'YYYY-MM')                           as year_month,
        'Q' || extract(quarter from date_day) || ' '
            || extract(year from date_day)                     as year_quarter,

        -- booleans
        case
            when extract(isodow from date_day) in (6, 7) then true
            else false
        end                                                    as is_weekend,

        case
            when extract(isodow from date_day) in (1, 2, 3, 4, 5) then true
            else false
        end                                                    as is_weekday

    from calendar_dates

)

select * from final