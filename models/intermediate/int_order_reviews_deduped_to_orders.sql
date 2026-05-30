with reviews as (
    select * from {{ ref('stg_olist__order_reviews') }}
),

deduped as (
    /*
        Source has duplicate reviews per order due to source system issue.
        We keep only the most recent review per order based on created_at.
    */
    select *,
        row_number() over (
            partition by order_id           -- one review per order
            order by created_at desc        -- latest review = row 1
        ) as row_num
    from reviews
),

final as (
    select
        -- grain: one row per order
        review_id,
        order_id,
        review_score,
        review_title,
        review_body,
        created_at,
        answered_at,
        sentiment,
        has_comment

    from deduped
    where row_num = 1
)

select * from final