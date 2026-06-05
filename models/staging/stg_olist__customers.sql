with source as (
    select * from {{ ref('snap_customers') }}
),

renamed as (
    select
        -- primary key
        customer_id,

        -- natural keys
        customer_unique_id,

        -- attributes
        customer_zip_code_prefix   as zip_code,
        customer_city              as city,
        customer_state             as state,

        -- snapshot metadata
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to

    from source
)

select * from renamed