{{ config(materialized='view') }}

select *
from {{ source('bronze','sbx_rewards_activity_raw') }}