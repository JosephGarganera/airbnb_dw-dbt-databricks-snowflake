{% set cols = ['nights_booked', 'booking_id', 'booking_amount'] %}

SELECT
{% for col in cols %}
  {{ col }} {% if not loop.last %},{% endif %}
{% endfor %} 
from {{ ref('bronze_bookings') }}  