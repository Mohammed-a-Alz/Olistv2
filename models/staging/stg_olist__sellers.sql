with source as (
    select * from {{ source('raw', 'RAW_SELLERS') }}
),

renamed as (
    select
        -- primary key
        seller_id,

        -- attributes
        seller_zip_code_prefix      as zip_code,
        seller_city                 as city,
        seller_state                as state

    from source
)

select * from renamed