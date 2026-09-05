{{
  config(
    materialized = 'incremental',
    unique_key = 'host_id'
  )
}}

with cleaned_hosts as (
  select
    host_id,
    replace(host_name, ' ', '_') as host_name,
    host_since,
    is_superhost,
    -- Data Quality Fix 1: Strip out characters like '%' and safely cast text to a number
    try_to_number(regexp_replace(response_rate, '[^0-9.]', '')) as numeric_response_rate,
    created_at
  from
    {{ ref('bronze_hosts') }}
)

select  
  host_id,
  host_name,
  host_since,
  is_superhost,
  numeric_response_rate as response_rate,
  -- Data Quality Fix 2: Isolate NULL values before evaluating numeric thresholds
  case  
    when numeric_response_rate is null then 'unknown'
    when numeric_response_rate > 95 then 'very good'
    when numeric_response_rate > 80 then 'good'
    when numeric_response_rate > 60 then 'fair'
    else 'poor'
  end as response_rate_quality,
  created_at
from
  cleaned_hosts

{% if is_incremental() %}
  where created_at > (select max(created_at) from {{ this }})
{% endif %}
