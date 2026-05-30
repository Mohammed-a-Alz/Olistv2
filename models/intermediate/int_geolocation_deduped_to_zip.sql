with geolocation as (
    select * from {{ ref('stg_olist__geolocation') }}
),

final as (
    /*
        Source has multiple coordinates per zip code.
        Taking average to get centroid point per zip.
    */
    select
        -- grain: one row per zip code
        zip_code,

        -- centroid coordinates
        avg(latitude)               as latitude,
        avg(longitude)              as longitude

    from geolocation
    group by zip_code
)

select * from final