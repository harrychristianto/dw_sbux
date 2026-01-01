{{ config(schema='SC_GOLD', materialized='table') }}

with portions as (
  select
    i.store_id,
    cast(t.order_ts_local as date) as order_date,
    i.menu_item_id,
    sum(i.quantity) as portions_sold
  from {{ ref('silver_sbx_sales_item') }} i
  join {{ ref('silver_sbx_sales_transaction') }} t
    on i.transaction_id = t.transaction_id
   and t.normalized_status = 'COMPLETED'
  group by 1,2,3
),
bom as (
  select menu_item_id, sku_id, qty_per_serving
  from {{ ref('silver_sbx_recipe_bom') }}
),
theoretical as (
  select
    p.store_id, p.order_date, b.sku_id,
    sum(p.portions_sold * b.qty_per_serving) as theoretical_qty
  from portions p
  join bom b on p.menu_item_id = b.menu_item_id
  group by 1,2,3
),
actual as (
  select
    cast(store_id as varchar) as store_id,
    cast(usage_date as date)  as order_date,
    cast(sku_id as varchar)   as sku_id,
    sum(cast(usage_qty as number)) as actual_qty
  from {{ source('bronze','sbx_inventory_usage_raw') }}
  group by 1,2,3
)
select
  {{ surrogate_key(['t.store_id','t.sku_id','t.order_date']) }} as inv_usage_key,
  t.store_id, t.sku_id, t.order_date,
  t.theoretical_qty,
  coalesce(a.actual_qty, 0) as actual_qty,
  coalesce(a.actual_qty, 0) - coalesce(t.theoretical_qty, 0) as variance_qty
from theoretical t
left join actual a
  on a.store_id = t.store_id
 and a.sku_id   = t.sku_id
 and a.order_date = t.order_date