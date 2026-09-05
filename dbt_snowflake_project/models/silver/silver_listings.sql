{{
  config(
    materialized = 'incremental',
    unique_key = 'listing_id'
  )
}}

with cleaned_listings as (
  select
    listing_id,
    host_id, -- Fix: Added missing comma to prevent accidental aliasing
    
    -- Data Quality Fix 1: Handle missing categorical data with a default label
    coalesce(trim(property_type), 'Unknown') as property_type,
    coalesce(trim(room_type), 'Unknown') as room_type,
    coalesce(trim(city), 'Unknown') as city,
    coalesce(trim(country), 'Unknown') as country,
    
    -- Data Quality Fix 2: Floor missing or negative capacities to 0 or 1
    case when accommodates < 0 or accommodates is null then 1 else accommodates end as accommodates,
    coalesce(bedrooms, 0) as bedrooms,
    coalesce(bathrooms, 0) as bathrooms,
    
    -- Data Quality Fix 3: Handle pricing anomalies safely
    case when price_per_night < 0 or price_per_night is null then 0.00 else price_per_night end as price_per_night,
    created_at
  from 
    {{ ref('bronze_listings') }}    
)

select
  listing_id,
  host_id,
  property_type,
  room_type,
  city,
  country,
  accommodates,
  bedrooms,
  bathrooms,
  price_per_night,
  -- This will now compile smoothly into your fixed CASE WHEN macro statement
  {{ tag('price_per_night') }} as price_per_night_tag,
  created_at
from 
  cleaned_listings

{% if is_incremental() %}
  -- Fix: Enforce consistent lowercase syntax formatting to match your project profile
  where created_at > (select max(created_at) from {{ this }})
{% endif %}
