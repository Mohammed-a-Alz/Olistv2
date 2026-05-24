with source as (
    select * from {{ source('raw', 'RAW_ORDER_REVIEWS') }}
),

deduped as (
    /*
        Source data contains duplicate reviews per order due to a source system issue.
        We keep only the most recent review per order based on review_creation_date.
    */
    select *,
        row_number() over (
            partition by order_id           -- one review per order
            order by review_creation_date desc  -- latest review = row 1
        ) as row_num
    from source
),

renamed as (
    select
        -- primary key
        review_id,

        -- foreign keys
        order_id,

        -- attributes 
        review_score,
        review_comment_title        as review_title,
        review_comment_message      as review_body,

        -- timestamps (convention: <event>_at)
        review_creation_date        as created_at,
        review_answer_timestamp     as answered_at,

        -- categorization
        case
            when review_score >= 4 then 'positive'
            when review_score = 3  then 'neutral'
            else                        'negative'
        end                         as sentiment,

        -- booleans (convention: is_/has_)
        case
            when review_comment_message is not null then true
            else false
        end                         as has_comment

    from deduped
    where row_num = 1
)

select * from renamed