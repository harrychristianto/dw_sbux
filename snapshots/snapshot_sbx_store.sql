
{% snapshot snapshot_sbx_store %}
  {{ config(
    target_database='DW_SBUX',
    target_schema='SC_SNAPSHOTS',
    unique_key='store_id',
    strategy='timestamp',
    updated_at='updated_at'
  ) }}

  select
    cast(store_id as string) as store_id,
    store_name,
    city,
    store_type,
    status,
    updated_at
  from {{ source('bronze','sbx_store_master_raw') }}

{% endsnapshot %}
