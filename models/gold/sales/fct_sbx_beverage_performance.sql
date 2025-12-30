{{ config(schema='SC_GOLD', materialized='incremental', unique_key='transaction_item_key') }}

with completed as (
  select
    i.transaction_item_key,
    i.transaction_id,
    i.store_id,
    i.menu_item_id,
    i.item_name_norm,
    i.menu_category,
    i.size, i.milk_type, i.syrup, i.extra_shot,
    i.quantity, i.unit_price, i.discount_amount, i.tax_amount, i.line_amount,
    t.ingestion_ts
  from {{ ref('silver_sbx_sales_item') }} i
  join {{ ref('silver_sbx_sales_transaction') }} t
    on i.transaction_id = t.transaction_id
   and t.normalized_status = 'COMPLETED'
  {% if is_incremental() %}
    where t.ingestion_ts > (select coalesce(max(updated_at), '1970-01-01') from {{ this }})
  {% endif %}
)
select
  transaction_item_key,
  transaction_id,
  store_id,
  menu_item_id,
  item_name_norm,
  menu_category,
  size, milk_type, syrup, extra_shot,
  quantity, unit_price, discount_amount, tax_amount, line_amount,
  current_timestamp() as updated_at
from completed;
