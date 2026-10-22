-- Redash query ID: 136891
-- Name: gng

SELECT
  DATE_PART('year', age(birth_date)) :: integer as age,
  sex,
  count(DISTINCT user_id) as users_count
from
  users
where
  birth_date IS NOT NULL
group by
  age,
  sex
order by
  age,
  sex
