with source as (
    select * from {{ source('raw', 'RAW_PRODUCTS') }}
),

renamed as (
    select
        -- primary key
        product_id,

        -- attributes
        product_category_name       as category,

        -- dimensions (fixing source typos: lenght → length)
        product_name_lenght::int        as name_length,
        product_description_lenght::int as description_length,
        product_photos_qty::int         as photos_count,
        product_weight_g::int           as weight_g,
        product_length_cm::int          as length_cm,
        product_height_cm::int          as height_cm,
        product_width_cm::int           as width_cm,

        -- computations
        (product_length_cm * product_height_cm * product_width_cm) as volume_cm3

    from source
)

select * from renamed