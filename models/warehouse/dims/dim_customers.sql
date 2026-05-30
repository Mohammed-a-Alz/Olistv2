with customers as (
    select * from {{ ref('stg_olist__customers') }}
),

orders as (
    select * from {{ ref('stg_olist__orders') }}
),

geolocation_raw as (
    select * from {{ ref('stg_olist__geolocation') }}
),

-- deduplicate: multiple coordinates per zip, take average centroid
geolocation as (
    select
        zip_code,
        avg(latitude)   as latitude,
        avg(longitude)  as longitude
    from geolocation_raw
    group by zip_code
),

customer_orders as (
    select
        customer_id,
        min(purchased_at)               as first_order_at,
        max(purchased_at)               as last_order_at,
        count(distinct order_id)        as total_orders,
        max(case when is_delivered then 1 else 0 end) as has_delivered_order
    from orders
    group by customer_id
),

final as (
    select
        -- primary key
        c.customer_id,
        c.customer_unique_id,

        -- location attributes
        c.zip_code,
        c.city,
        c.state,

        -- geolocation
        g.latitude,
        g.longitude,

        -- lifecycle attributes
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