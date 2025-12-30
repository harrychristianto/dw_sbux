{{ config(
  schema='SC_SILVER',
  materialized='incremental',
  unique_key='transaction_id',
  on_schema_change='sync_all_columns'
) }}

with pos as (
  select
    cast(order_id as string)                as transaction_id,
    cast(store_id as string)                as store_id,
    cast(member_id as string)               as member_id,
    {{ convert_to_tz('order_ts', 'Asia/Jakarta') }} as order_ts_local,
    upper(coalesce(order_channel, 'POS'))   as channel,
    upper(coalesce(order_type, 'DINE_IN'))  as order_type,
    subtotal_amount, discount_amount, tax_amount, service_charge_amount, total_amount,
    upper(coalesce(order_status,'PENDING')) as order_status,
    ingestion_ts
  from {{ source('bronze','sbx_pos_sales_raw') }}
  {% if is_incremental() %}
    where ingestion_ts > (select coalesce(max(ingestion_ts), '1970-01-01') from {{ this }})
  {% endif %}
),
delivery as (
  select
    cast(delivery_order_id as string)       as transaction_id,
    cast(store_id as string)                as store_id,
    cast(null as string)                    as member_id,
    {{ convert_to_tz('order_ts', 'Asia/Jakarta') }} as order_ts_local,
    upper(platform)                         as channel,     -- GRABFOOD / GOFOOD
    'DELIVERY'                              as order_type,
    subtotal_amount, discount_amount, tax_amount, service_charge_amount, total_amount,
    upper(coalesce(status,'PENDING'))       as order_status,
    ingestion_ts
  from {{ source('bronze','sbx_delivery_orders_raw') }}
  {% if is_incremental() %}
    where ingestion_ts > (select coalesce(max(ingestion_ts), '1970-01-01') from {{ this }})
  {% endif %}
),
unified as (
  select * from pos
  union all
  select * from delivery
)
select
  transaction_id,
  store_id,
  coalesce(member_id, 'NON_MEMBER') as member_id,
  order_ts_local,
  channel,
  order_type,
  round(coalesce(subtotal_amount,0) - coalesce(discount_amount,0)
    + coalesce(service_charge_amount,0) + coalesce(tax_amount,0), 2) as net_sales_amount,
  round(coalesce(total_amount,0), 2) as gross_amount,
  case
    when order_status in ('VOID','CANCELLED') then 'CANCELLED'
    when order_status in ('PAID','COMPLETED') then 'COMPLETED'
    else 'PENDING'
  end as normalized_status,
  ingestion_ts
from unified;
