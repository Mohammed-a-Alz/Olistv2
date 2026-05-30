with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

payments as (
    select * from {{ ref('int_payments_aggregated_to_orders') }}
),

reviews as (
    select * from {{ ref('int_order_reviews_deduped_to_orders') }}
),

final as (
    select
        -- primary key
        o.order_id,

        -- foreign keys
        o.customer_id,

        -- status flags
        o.order_status,
        o.is_delivered,
        o.is_canceled,

        -- computed flag
        case
            when o.delivered_to_customer_at > o.estimated_delivery_at then true
            else false
        end                                 as is_late_delivery,

        -- measures
        o.delivery_days,
        datediff('day',
            o.delivered_to_customer_at,
            o.estimated_delivery_at)        as delivery_vs_estimate_days,

        -- payment measures
        coalesce(p.total_payment_brl, 0)    as revenue_brl,
        coalesce(p.max_installments, 0)     as max_installments,

        -- review measures
        r.review_score,

        -- timestamps
        o.purchased_at,
        o.approved_at,
        o.delivered_to_carrier_at,
        o.delivered_to_customer_at,
        o.estimated_delivery_at

    from orders o
    left join payments p    on o.order_id = p.order_id
    left join reviews r     on o.order_id = r.order_id
)

select * from final