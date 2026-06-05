{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=[ 
            'customer_zip_code_prefix',
            'customer_city',
            'customer_state'
        ]
    )
}}

select * from {{ source('raw', 'RAW_CUSTOMERS') }}

{% endsnapshot %}