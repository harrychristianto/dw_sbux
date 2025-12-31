--remarkupdate
{{ config(
  materialized='table'
) }}

select
  -- Snowflake: gunakan VARCHAR
  cast(store_id as varchar)  as store_id,
  cast(sku_id   as varchar)  as sku_id,

  -- Jika di bronze sudah DATE, gunakan langsung. Jika string/timestamp, pakai TO_DATE().
  stock_date                 as stock_date
  -- atau: to_date(stock_date) as stock_date

, cast(opening_qty    as number(18,4)) as opening_qty
, cast(receipt_qty    as number(18,4)) as receipt_qty
, cast(usage_qty      as number(18,4)) as usage_qty
, cast(adjustment_qty as number(18,4)) as adjustment_qty

, cast(
    coalesce(opening_qty, 0)
  + coalesce(receipt_qty, 0)
  - coalesce(usage_qty, 0)
  + coalesce(adjustment_qty, 0)
  as number(18,4)
) as closing_qty

, cast(unit_cost as number(18,4)) as unit_cost
, ingestion_ts
from {{ source('bronze','sbx_inventory_stock_raw') }}