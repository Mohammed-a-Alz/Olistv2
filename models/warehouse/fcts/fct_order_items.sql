with order_items as (
    select * from {{ ref('stg_olist__order_items') }}
),

orders as (
    select * from {{ ref('stg_olist__orders') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['oi.order_id', 'oi.item_id']) }} as order_item_sk,

        -- foreign keys
        oi.order_id,
        oi.item_id,
        oi.product_id,
        oi.seller_id,

        -- order context
        o.purchased_at,
        o.is_delivered,
        o.is_canceled,

        -- measures
        oi.price_brl,
        oi.freight_brl,
        oi.total_amount_brl,

        -- timestamps
        oi.ship_by_at

    from order_items oi
    left join orders o on oi.order_id = o.order_id
)

select * from final