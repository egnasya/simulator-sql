-- Redash query ID: 137045
-- Name: доли_пользователей_с_одним_и_несколькими_заказами_по_дням

-- Для каждого дня, представленного в таблице user_actions, рассчитайте следующие показатели:
--  - Долю пользователей, сделавших в этот день всего один заказ, в общем количестве платящих пользователей.
--  - Долю пользователей, сделавших в этот день несколько заказов, в общем количестве платящих пользователей.
-- Колонки с показателями назовите соответственно single_order_users_share, several_orders_users_share. Колонку с датами назовите date. Все показатели
-- с долями необходимо выразить в процентах. При расчёте долей округляйте значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, single_order_users_share, several_orders_users_share

WITH count_paying_users AS (
    SELECT 
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY 1
), 

user_order_counts AS (
    SELECT 
        date,
        COUNT(DISTINCT user_id) FILTER(WHERE count_orders = 1) AS one_order,
        COUNT(DISTINCT user_id) FILTER(WHERE count_orders > 1) AS more_one_order
    FROM (
        SELECT
            time::date AS date,
            user_id,
            COUNT(order_id) AS count_orders
        FROM user_actions
        WHERE action != 'cancel_order' AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        GROUP BY 1,2
        ) cuo
    GROUP BY date
)

SELECT
    pu.date,
    ROUND(one_order::decimal / paying_users * 100, 2) AS single_order_users_share,
    ROUND(more_one_order::decimal / paying_users * 100, 2) AS several_orders_users_share
FROM count_paying_users pu 
    LEFT JOIN user_order_counts uo ON pu.date = uo.date
