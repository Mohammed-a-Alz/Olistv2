with source as (
    select * from {{ source('raw', 'RAW_ORDER_REVIEWS') }}
),

renamed as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title        as review_title,
        review_comment_message      as review_body,
        review_creation_date        as created_at,
        review_answer_timestamp     as answered_at,

        case
            when review_score >= 4 then 'positive'
            when review_score = 3  then 'neutral'
            else                        'negative'
        end                         as sentiment,

        case
            when review_comment_message is not null then true
            else false
        end                         as has_comment

    from source
)

select * from renamed