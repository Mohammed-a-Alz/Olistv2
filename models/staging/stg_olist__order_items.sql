with source as (
    select * from {{ source('raw', 'RAW_ORDER_ITEMS') }}
),

renamed as (
    select
        -- primary keys
        order_id,
        order_item_id               as item_id,

        -- foreign keys
        product_id,
        seller_id,

        -- timestamps
        shipping_limit_date         as ship_by_at,

        -- amounts (convention: include currency unit)
        price::float                as price_brl,
        freight_value::float        as freight_brl,

        -- computations
        price + freight_value       as total_amount_brl

    from source
)

select * from renamed