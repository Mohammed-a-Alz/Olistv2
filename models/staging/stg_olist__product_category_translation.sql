with source as (
    select * from {{ source('raw', 'RAW_PRODUCT_CATEGORY_TRANSLATION') }}
),

renamed as (
    select
        -- primary key
        product_category_name       as category_portuguese,

        -- attributes
        product_category_name_english as category_english

    from source
)

select * from renamed