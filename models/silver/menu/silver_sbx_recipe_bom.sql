
{{ config(materialized='view') }}

select
  cast(menu_item_id as varchar) as menu_item_id,
  cast(sku_id      as varchar)  as sku_id,
  cast(quantity    as number(18,4)) as qty_per_serving,
  uom,
  ingestion_ts
from {{ source('bronze','sbx_recipe_bom_raw') }}
