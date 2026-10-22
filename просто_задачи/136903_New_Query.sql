-- Redash query ID: 136903
-- Name: New Query

/*
Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:

Число новых пользователей.
Число новых курьеров.
Общее число пользователей на текущий день.
Общее число курьеров на текущий день.
Колонки с показателями назовите соответственно new_users, new_couriers, total_users, total_couriers. 
Колонку с датами назовите date. Проследите за тем, чтобы показатели были выражены целыми числами. Результат должен быть отсортирован по возрастанию даты.

Поля в результирующей таблице: date, new_users, new_couriers, total_users, total_couriers
*/

WITH user_stats AS (
    SELECT 
        time::date AS date,
        COUNT(user_id) FILTER (WHERE time = FIRST_VALUE(time) OVER(PARTITION BY user_id ORDER BY time)) AS new_users,
        COUNT(DISTINCT user_id) OVER(ORDER BY time::date) AS total_users
    FROM user_actions
    GROUP BY date
)

select * from user_stats
