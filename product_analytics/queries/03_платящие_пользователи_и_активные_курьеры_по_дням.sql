-- Redash query ID: 136976
-- Name: платящие_пользователи_и_активные_курьеры_по_дням

-- Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:
--  - Число платящих пользователей.
--  - Число активных курьеров.
--  - Долю платящих пользователей в общем числе пользователей на текущий день.
--  - Долю активных курьеров в общем числе курьеров на текущий день.
-- Проследите за тем, чтобы абсолютные показатели были выражены целыми числами. Все показатели долей необходимо выразить в процентах. При их расчёте округляйте 
-- значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты. 

-- Поля в результирующей таблице: date, paying_users, active_couriers, paying_users_share, active_couriers_share

WITH paying_users AS (
    SELECT 
        DISTINCT time::date AS date,
        COUNT(user_id) OVER(PARTITION BY time::date) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY 1, user_id
),

active_couriers AS (
    SELECT
        DISTINCT time::date AS date,
        COUNT(courier_id) OVER(PARTITION BY time::date) AS active_couriers
    FROM courier_actions ca
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
    GROUP BY 1, courier_id
),

all_users AS (
    SELECT
        date,
        SUM(new_users) OVER(ORDER BY date) AS all_users
    FROM (
        SELECT
            date,
            COUNT(user_id) AS new_users
        FROM (
            SELECT
                time :: date AS date,
                user_id,
                order_id,
                ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) AS user_order_number
            FROM
                user_actions
            ) t1
        WHERE user_order_number = 1
        GROUP BY date
        ) t2
),

all_new_couriers AS (
    SELECT
        date,
        SUM(new_couriers) OVER(ORDER BY date) AS all_couriers
    FROM (
        SELECT
            date,
            COUNT(courier_id) AS new_couriers
        FROM (
            SELECT
                time :: date AS date,
                courier_id,
                order_id,
                ROW_NUMBER() OVER(PARTITION BY courier_id ORDER BY time) AS courier_order_number
            FROM
                courier_actions
            ) t3
        WHERE courier_order_number = 1
        GROUP BY date
        ) t4
)

SELECT
    py.date,
    paying_users,
    active_couriers,
    ROUND(paying_users::decimal / au.all_users * 100, 2) AS paying_users_share,
    ROUND(active_couriers::decimal / anc.all_couriers * 100, 2) AS active_couriers_share
FROM paying_users py
    LEFT JOIN active_couriers ac
    ON py.date = ac.date
    LEFT JOIN all_users au 
    ON py.date = au.date
    LEFT JOIN all_new_couriers anc 
    ON py.date = anc.date 
ORDER BY py.date
