with source as (
    select * from {{ source('raw', 'RAW_ORDERS') }}
),

renamed as (
    select
        -- primary key
        order_id,

        -- foreign keys
        customer_id,

        -- attributes
        order_status                                as order_status,

        -- timestamps (convention: <event>_at)
        order_purchase_timestamp                    as purchased_at,
        order_approved_at                           as approved_at,
        order_delivered_carrier_date                as delivered_to_carrier_at,
        order_delivered_customer_date               as delivered_to_customer_at,
        order_estimated_delivery_date               as estimated_delivery_at,

        -- booleans (convention: is_/has_)
        case
            when order_status = 'delivered' then true
            else false
        end                                         as is_delivered,

        case
            when order_status in ('canceled', 'unavailable') then true
            else false
        end                                         as is_canceled,

        -- computations
        datediff('day',
            order_purchase_timestamp,
            order_delivered_customer_date)          as delivery_days

    from source
)

select * from renamed