
{{ config(schema='SC_GOLD', materialized='table') }}

with tx as (
  select
    store_id,
    channel,
    order_type,
    date(order_ts_local) as order_date,
    extract(hour from order_ts_local) as order_hour,
    net_sales_amount,
    gross_amount
  from {{ ref('silver_sbx_sales_transaction') }}
  where normalized_status = 'COMPLETED'
),
daypart as (
  select
    store_id, channel, order_type, order_date,
    case
      when order_hour between 5 and 9  then 'MORNING'
      when order_hour between 10 and 13 then 'MIDDAY'
      when order_hour between 14 and 16 then 'AFTERNOON'
      else 'EVENING'
    end as daypart,
    net_sales_amount, gross_amount
  from tx
),
agg as (
  select
    store_id, channel, order_type, order_date, daypart,
    count(*)                              as order_count,
    sum(net_sales_amount)                 as net_sales,
    sum(gross_amount)                     as gross_sales,
    safe_divide(sum(net_sales_amount), nullif(count(*),0)) as aov
  from daypart
  group by 1,2,3,4,5
)
select
  {{ surrogate_key(['store_id','channel','order_type','order_date','daypart']) }} as sales_daily_key,
  store_id, channel, order_type, order_date, daypart,
  order_count, net_sales, gross_sales, aov
from agg;
