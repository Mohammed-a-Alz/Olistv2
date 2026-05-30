with customers as (
    select * from {{ ref('stg_olist__customers') }}
),

geolocation as (
    select * from {{ ref('int_geolocation_deduped_to_zip') }}
),

customer_orders as (
    select * from {{ ref('int_orders_aggregated_to_customers') }}
),

final as (
    select
        -- primary key
        c.customer_id,
        c.customer_unique_id,

        -- attributes
        c.zip_code,
        c.city,
        c.state,

        -- geolocation
        g.latitude,
        g.longitude,

        -- lifecycle
        co.first_order_at,
        co.last_order_at,

        -- behavioral categories
        case
            when co.total_orders > 1 then true
            else false
        end                             as is_repeat_customer,

        case
            when co.has_delivered_order = 1 then true
            else false
        end                             as has_delivered_order

    from customers c
    left join geolocation g         on c.zip_code = g.zip_code
    left join customer_orders co    on c.customer_id = co.customer_id
)

select * from final