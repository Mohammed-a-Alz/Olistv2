with sellers as (
    select * from {{ ref('stg_olist__sellers') }}
),

geolocation as (
    select * from {{ ref('int_geolocation_deduped_to_zip') }}
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