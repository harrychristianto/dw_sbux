
{{ config(schema='SC_GOLD', materialized='table') }}

with item_sales as (
  select
    t.store_id,
    date(t.order_ts_local) as order_date,
    i.menu_item_id,
    i.item_name_norm,
    sum(i.quantity)        as qty_sold,
    sum(i.line_amount)     as revenue
  from {{ ref('silver_sbx_sales_item') }} i
  join {{ ref('silver_sbx_sales_transaction') }} t
    on i.transaction_id = t.transaction_id
   and t.normalized_status = 'COMPLETED'
  group by 1,2,3,4
),
bom as (
  select menu_item_id, sku_id, qty_per_serving
  from {{ ref('silver_sbx_recipe_bom') }}
),
sku_cost as (
  select
    store_id, sku_id, stock_date,
    avg(unit_cost) as avg_unit_cost
  from {{ ref('silver_sbx_inventory_stock') }}
  group by 1,2,3
),
cost_per_serving as (
  select
    b.menu_item_id,
    sum(b.qty_per_serving * sc.avg_unit_cost) as cost_per_serving
  from bom b
  left join sku_cost sc
    on sc.sku_id = b.sku_id
  group by b.menu_item_id
)
select
  {{ surrogate_key(['is.store_id','is.menu_item_id','is.order_date']) }} as menu_profit_key,
  is.store_id,
  is.order_date,
  is.menu_item_id,
  is.item_name_norm,
  is.qty_sold,
  is.revenue,
  coalesce(c.cost_per_serving, 0) as cost_per_serving,
  (is.qty_sold * coalesce(c.cost_per_serving, 0)) as total_cost,
  (is.revenue - (is.qty_sold * coalesce(c.cost_per_serving, 0))) as contribution_margin
from item_sales is
left join cost_per_serving c
  on c.menu_item_id = is.menu_item_id;
