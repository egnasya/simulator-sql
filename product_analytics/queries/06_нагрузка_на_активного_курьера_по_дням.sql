-- Redash query ID: 137129
-- Name: нагрузка_на_активного_курьера_по_дням

-- На основе данных в таблицах user_actions, courier_actions и orders для каждого дня рассчитайте следующие показатели:
--  - Число платящих пользователей на одного активного курьера.
--  - Число заказов на одного активного курьера.
-- При расчёте показателей округляйте значения до двух знаков после запятой. Результирующая таблица должна быть отсортирована по возрастанию даты.
-- Поля в результирующей таблице: date, users_per_courier, orders_per_courier

WITH paying_users AS (
    SELECT 
        time::date AS date,
        COUNT(DISTINCT user_id) AS paying_users,
        COUNT(DISTINCT order_id) AS total_orders
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY time::date
),
active_couriers AS (
    SELECT
        time::date AS date,
        COUNT(DISTINCT courier_id) AS active_couriers
    FROM courier_actions
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
    GROUP BY time::date
)

SELECT
    py.date,
    ROUND(paying_users::decimal / active_couriers, 2) AS users_per_courier,
    ROUND(total_orders::decimal / active_couriers, 2) AS orders_per_courier
FROM paying_users py
    JOIN active_couriers ac ON py.date = ac.date
