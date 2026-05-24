with source as (
    select * from {{ source('raw', 'RAW_CUSTOMERS') }}
),

renamed as (
    select
        -- primary key
        customer_id,

        -- natural keys
        customer_unique_id,

        -- attributes
        customer_zip_code_prefix    as zip_code,
        customer_city               as city,
        customer_state              as state

    from source
)

select * from renamed