{{ config(schema='SC_SILVER', materialized='table') }}

select
  cast(store_id as string)  as store_id,
  cast(sku_id as string)    as sku_id,
  date(stock_date)          as stock_date,
  cast(opening_qty as numeric)    as opening_qty,
  cast(receipt_qty as numeric)    as receipt_qty,
  cast(usage_qty as numeric)      as usage_qty,
  cast(adjustment_qty as numeric) as adjustment_qty,
  opening_qty + receipt_qty - usage_qty + adjustment_qty as closing_qty,
  unit_cost,
  ingestion_ts
from {{ source('bronze','sbx_inventory_stock_raw') }};
