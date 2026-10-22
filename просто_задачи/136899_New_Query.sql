-- Redash query ID: 136899
-- Name: New Query

WITH t as (SELECT user_id, time::date as date,
MIN(time::date) OVER (PARTITION BY user_id) as start_date
FROM user_actions),
cohorts as (SELECT 
start_date, 
date-start_date AS day_number,
COUNT(DISTINCT user_id) as users 
FROM t
GROUP BY start_date,date )
SELECT 
DATE_TRUNC('month', start_date)::date as start_month,
start_date,	day_number,	
ROUND(users::decimal/MAX(users) OVER (PARTITION BY start_date),2) as retention
FROM cohorts
ORDER BY start_date, day_number
