{{ config(schema='SC_GOLD', materialized='table') }}

select
  cast(store_id as varchar)               as store_id,
  upper(trim(store_name))                 as store_name,
  upper(trim(city))                       as city,
  upper(coalesce(store_type,'MALL'))      as store_type,  -- MALL, STREET, DRIVE_THRU
  upper(coalesce(status,'OPEN'))          as status
from {{ source('bronze','sbx_store_master_raw') }};