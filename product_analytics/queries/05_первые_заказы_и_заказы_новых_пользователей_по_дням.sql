-- Redash query ID: 137127
-- Name: первые_заказы_и_заказы_новых_пользователей_по_дням

-- Для каждого дня, представленного в таблице user_actions, рассчитайте следующие показатели:
--  - Общее число заказов.
--  - Число первых заказов (заказов, сделанных пользователями впервые).
--  - Число заказов новых пользователей (заказов, сделанных пользователями в тот же день, когда они впервые воспользовались сервисом).
--  - Долю первых заказов в общем числе заказов (долю п.2 в п.1).
--  - Долю заказов новых пользователей в общем числе заказов (долю п.3 в п.1).
-- Проследите за тем, чтобы во всех случаях количество заказов было выражено целым числом. Все показатели с долями необходимо выразить в процентах. При расчёте долей 
-- округляйте значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, orders, first_orders, new_users_orders, first_orders_share, new_users_orders_share

SELECT 
    date,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) FILTER(WHERE order_number = 1) AS first_orders,
    COUNT(DISTINCT order_id) FILTER(WHERE date = date_firs_order::date) AS new_users_orders,
    ROUND(COUNT(DISTINCT order_id) FILTER(WHERE order_number = 1) / COUNT(DISTINCT order_id)::decimal * 100, 2) AS first_orders_share,
    ROUND(COUNT(DISTINCT order_id) FILTER(WHERE date = date_firs_order) / COUNT(DISTINCT order_id)::decimal * 100, 2) AS new_users_orders_share
FROM (
    SELECT
        time::date AS date,
        ua.user_id,
        order_id,
        ROW_NUMBER() OVER(PARTITION BY ua.user_id ORDER BY time) AS order_number,
        fd.date_firs_order AS date_firs_order
    FROM user_actions ua
    JOIN (SELECT user_id, MIN(time::date) OVER(PARTITION BY user_id) AS date_firs_order FROM user_actions) fd ON ua.user_id = fd.user_id
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
) t
GROUP BY date
ORDER BY date
