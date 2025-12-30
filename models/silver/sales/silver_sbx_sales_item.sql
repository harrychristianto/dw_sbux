{{ config(
  schema='SC_SILVER',
  materialized='incremental',
  unique_key='transaction_item_key'
) }}

with items as (
  select
    cast(order_item_id as string)   as order_item_id,
    cast(order_id as string)        as transaction_id,
    cast(store_id as string)        as store_id,
    cast(item_id as string)         as menu_item_id,
    upper(trim(item_name))          as item_name_norm,
    quantity, unit_price, discount_amount, tax_amount,
    modifiers_json,
    ingestion_ts
  from {{ source('bronze','sbx_pos_order_items_raw') }}
  {% if is_incremental() %}
    where ingestion_ts > (select coalesce(max(ingestion_ts), '1970-01-01') from {{ this }})
  {% endif %}
),
menu as (
  select
    cast(menu_item_id as string)         as menu_item_id,
    upper(trim(menu_item_name))          as menu_item_name_norm,
    upper(coalesce(category,'UNCATEGORIZED')) as category
  from {{ source('bronze','sbx_menu_item_raw') }}
),
parsed as (
  select
    i.*,
    {{ json_extract('modifiers_json', '$.size') }}        as size,
    {{ json_extract('modifiers_json', '$.milk') }}        as milk_type,
    {{ json_extract('modifiers_json', '$.syrup') }}       as syrup,
    cast({{ json_extract('modifiers_json', '$.extra_shot') }} as int) as extra_shot
  from items i
)
select
  concat(transaction_id, '-', order_item_id) as transaction_item_key,
  p.transaction_id,
  p.store_id,
  p.menu_item_id,
  p.item_name_norm,
  coalesce(m.category, 'UNCATEGORIZED') as menu_category,
  p.size, p.milk_type, p.syrup,
  coalesce(p.extra_shot, 0) as extra_shot,
  p.quantity, p.unit_price, p.discount_amount, p.tax_amount,
  round(p.quantity * p.unit_price - coalesce(p.discount_amount,0) + coalesce(p.tax_amount,0), 2) as line_amount,
  p.ingestion_ts
from parsed p
left join menu m
  on p.menu_item_id = m.menu_item_id;
