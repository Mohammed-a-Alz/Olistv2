with payments as (
    select * from {{ ref('stg_olist__order_payments') }}
),

orders as (
    select * from {{ ref('stg_olist__orders') }}
),

final as (
    select
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['p.order_id', 'p.payment_sequence']) }} as payment_sk,

        -- foreign keys
        p.order_id,
        p.payment_sequence,
        o.customer_id,

        -- payment attributes
        p.payment_type,
        p.installments,

        -- measures
        p.payment_amount_brl,

        -- booleans
        p.is_credit_card,
        p.is_installment,

        -- order context
        o.purchased_at,
        o.is_delivered,
        o.is_canceled

    from payments p
    left join orders o on p.order_id = o.order_id
)

select * from final