
{{ config(schema='SC_GOLD', materialized='table') }}

select
  cast(menu_item_id as string)                as menu_item_id,
  upper(trim(menu_item_name))                 as menu_item_name,
  upper(coalesce(category,'BEVERAGE'))        as category,
  coalesce(is_active, true)                   as is_active
from {{ source('bronze','sbx_menu_item_raw') }};
