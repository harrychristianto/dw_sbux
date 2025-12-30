{{ config(schema='SC_SILVER', materialized='view') }}

select
  cast(menu_item_id as string) as menu_item_id,
  cast(sku_id as string)       as sku_id,
  cast(quantity as numeric)    as qty_per_serving,
  uom,
  ingestion_ts
from {{ source('bronze','sbx_recipe_bom_raw') }};
