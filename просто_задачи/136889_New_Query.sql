-- Redash query ID: 136889
-- Name: New Query

with first_days as(
    select courier_id, min(time::date) as first_date
    from courier_actions
    group by courier_id
),
daily_new as (
    select first_date as date, count(courier_id) as new_couriers
    from first_days
    group by first_date
),
first_days_users as(
    select user_id, min(time::date) as first_date_users
    from user_actions
    group by user_id
),
daily_new_users as (
    select count(user_id) as new_users, first_date_users as date
    from first_days_users
    group by first_date_users
)
select
    coalesce(c.date, u.date) as date,
    u.new_users,
    c.new_couriers,
    sum(u.new_users) over (order by coalesce(c.date, u.date))::int as total_users,
    sum(c.new_couriers) OVER (ORDER BY coalesce(c.date, u.date))::int as total_couriers
from daily_new_users u
    full join daily_new c on u.date = c.date
order by date
