-- Redash query ID: 136901
-- Name: New Query

select date_trunc('month',time) as month,
       count(distinct user_id)
from user_actions
group by month
