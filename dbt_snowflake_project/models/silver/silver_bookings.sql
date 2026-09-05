{{
  config(
    materialized = 'incremental',
    unique_key = 'booking_id'
  )
}}

with verified_bookings as (
  select
    booking_id,
    listing_id,
    booking_date,
    -- Data Quality Fix 1: Ensure raw numeric inputs are treated as 0 if missing/null
    coalesce(nights_booked, 0) as nights_booked,
    coalesce(booking_amount, 0) as booking_amount,
    coalesce(cleaning_fee, 0) as cleaning_fee,
    coalesce(service_fee, 0) as service_fee,
    -- Data Quality Fix 2: Handle string variations/nulls for categorical logic
    coalesce(lower(trim(booking_status)), 'unknown') as booking_status,
    created_at
  from 
    {{ ref('bronze_bookings') }}
),

calculated_amounts as (
  select
    booking_id,
    listing_id,
    booking_date,
    -- Apply your custom project math macro safely on top of cleaned base values
    {{ multiply('nights_booked', 'booking_amount', 2) }} 
      + cleaning_fee 
      + service_fee as calculated_total,
    booking_status,
    created_at
  from 
    verified_bookings
)

select
  booking_id,
  listing_id,
  booking_date,
  -- Data Quality Fix 3: Floor financial anomalies to 0 to prevent downstream accounting skew
  case 
    when calculated_total < 0 then 0.00
    else calculated_total
  end as total_amount,
  booking_status,
  created_at
from 
  calculated_amounts

{% if is_incremental() %}
  where created_at > (select max(created_at) from {{ this }})
{% endif %}
