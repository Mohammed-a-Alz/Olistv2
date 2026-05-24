with source as (
    select * from {{ source('raw', 'RAW_ORDER_PAYMENTS') }}
),

renamed as (
    select
        -- primary key
        order_id,
        payment_sequential          as payment_sequence,

        -- attributes
        payment_type,
        payment_installments        as installments,
        payment_value::float        as payment_amount_brl,

        -- booleans (convention: is_/has_)
        case
            when payment_type = 'credit_card' then true
            else false
        end                         as is_credit_card,

        case
            when payment_installments > 1 then true
            else false
        end                         as is_installment

    from source
)

select * from renamed