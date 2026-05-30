with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

final as (
    select
        -- grain: one row per customer
        customer_id,

        -- aggregated order history
        min(purchased_at)               as first_order_at,
        max(purchased_at)               as last_order_at,
        count(distinct order_id)        as total_orders,
        max(case when is_delivered then 1 else 0 end) as has_delivered_order

    from orders
    group by customer_id
)

select * from final