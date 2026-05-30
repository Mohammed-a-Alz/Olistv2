with orders as (
    select * from {{ ref('stg_olist__orders') }}
),

payments_raw as (
    select * from {{ ref('stg_olist__order_payments') }}
),

reviews as (
    select * from {{ ref('stg_olist__order_reviews') }}
),

-- aggregate payments to order grain
payments as (
    select
        order_id,
        sum(payment_amount_brl)     as revenue_brl,
        count(*)                    as payment_count,
        max(installments)           as max_installments
    from payments_raw
    group by order_id
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
        o.is_late_delivery,

        -- measures
        o.delivery_days,
        datediff('day',
            o.delivered_to_customer_at,
            o.estimated_delivery_at)    as delivery_vs_estimate_days,

        -- payment measures
        coalesce(p.revenue_brl, 0)      as revenue_brl,
        coalesce(p.payment_count, 0)    as payment_count,
        coalesce(p.max_installments, 0) as max_installments,

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