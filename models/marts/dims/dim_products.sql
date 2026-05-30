with products as (
    select * from {{ ref('stg_olist__products') }}
),

translations as (
    select * from {{ ref('stg_olist__product_category_translation') }}
),

final as (
    select
        -- primary key
        p.product_id,

        -- attributes
        p.category                  as category_portuguese,
        t.category_english,

        -- physical attributes
        p.weight_g,
        p.length_cm,
        p.height_cm,
        p.width_cm,
        p.volume_cm3,
        p.photos_count

    from products p
    left join translations t on p.category = t.category_portuguese
)

select * from final