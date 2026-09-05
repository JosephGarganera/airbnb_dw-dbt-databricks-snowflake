{% set flag = 1 %}


SELECT * FROM {{ ref('bronze_bookings')}}
{% if flag == 1 %}
    where nights_booked > 1
{% else %}
    where nights_booked = 1
{% endif %}