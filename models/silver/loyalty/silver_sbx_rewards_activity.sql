{{ config(materialized='view') }}

select
  cast(transaction_id as varchar) as transaction_id,
  cast(member_id as varchar)      as member_id,
  {{ convert_to_tz('activity_ts', 'Asia/Jakarta') }} as activity_ts_local,
  upper(activity_type)           as activity_type,  -- EARN / REDEEM
  stars_earned,
  stars_redeemed,
  ingestion_ts
from {{ source('bronze','sbx_rewards_activity_raw') }};
