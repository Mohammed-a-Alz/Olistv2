with source as (
    select * from {{ source('raw', 'RAW_GEOLOCATION') }}
),

renamed as (
    select
        -- primary key
        geolocation_zip_code_prefix as zip_code,

        -- coordinates
        geolocation_lat::float      as latitude,
        geolocation_lng::float      as longitude,

        -- attributes
        geolocation_city            as city,
        geolocation_state           as state

    from source
)

select * from renamed