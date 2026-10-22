-- Redash query ID: 136894
-- Name: New Query

select courier_id, DATE_PART('year', birth_date) as birth_year
from couriers;
