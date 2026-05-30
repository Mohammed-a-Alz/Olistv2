with sellers as (
    select * from {{ ref('stg_olist__sellers') }}
),

geolocation_raw as (
    select * from {{ ref('stg_olist__geolocation') }}
),

-- deduplicate: multiple coordinates per zip, take average centroid
geolocation as (
    select
        zip_code,
        avg(latitude)   as latitude,
        avg(longitude)  as longitude
    from geolocation_raw
    group by zip_code
),

final as (
    select
        -- primary key
        s.seller_id,

        -- attributes
        s.zip_code,
        s.city,
        s.state,

        -- geolocation
        g.latitude,
        g.longitude

    from sellers s
    left join geolocation g on s.zip_code = g.zip_code
)

select * from final