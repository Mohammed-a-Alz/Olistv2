{%- set payment_methods = ['credit_card', 'boleto', 'voucher', 'debit_card'] -%}

with payments as (
    select * from {{ ref('stg_olist__order_payments') }}
),

pivot_and_aggregate_payments_to_order_grain as (
    select
        order_id,

        -- pivot payment types into columns
        {% for payment_method in payment_methods -%}
        sum(
            case
                when payment_type = '{{ payment_method }}'
                then payment_amount_brl
                else 0
            end
        ) as {{ payment_method }}_amount,
        {% endfor %}

        -- total measures
        sum(payment_amount_brl)     as total_payment_brl,
        max(installments)           as max_installments,
        count(*)                    as payment_count,

        -- flags
        case
            when count(*) > 1 then true
            else false
        end                         as has_multiple_payments

    from payments
    group by order_id
)

select * from pivot_and_aggregate_payments_to_order_grain