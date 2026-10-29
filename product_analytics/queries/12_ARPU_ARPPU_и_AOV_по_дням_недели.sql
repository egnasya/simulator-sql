-- Redash query ID: 137319
-- Name: ARPU_ARPPU_и_AOV_по_дням_недели

-- Для каждого дня недели в таблицах orders и user_actions рассчитайте следующие показатели:
--  - Выручку на пользователя (ARPU).
--  - Выручку на платящего пользователя (ARPPU).
--  - Выручку на заказ (AOV).
-- При расчётах учитывайте данные только за период с 26 августа 2022 года по 8 сентября 2022 года включительно — так, чтобы в анализ попало одинаковое количество 
-- всех дней недели (ровно по два дня). В результирующую таблицу включите как наименования дней недели (например, Monday), так и порядковый номер дня недели 
-- (от 1 до 7, где 1 — это Monday, 7 — это Sunday). При расчёте всех показателей округляйте значения до двух знаков после запятой.
-- Результат должен быть отсортирован по возрастанию порядкового номера дня недели.
-- Поля в результирующей таблице: weekday, weekday_number, arpu, arppu, aov

WITH revenue AS (
    SELECT
        weekday,
        weekday_number,
        SUM(price) AS revenue
    FROM (SELECT 
            to_char(creation_time::date, 'Day') AS weekday,
            CASE
                WHEN DATE_PART('dow', creation_time::date) = 0.0 THEN 7.0
                ELSE DATE_PART('dow', creation_time::date)
            END AS weekday_number,
            order_id,
            pl.product_id,
            price
        FROM orders o 
            CROSS JOIN LATERAL unnest(o.product_ids) AS pl(product_id)
            JOIN products p ON pl.product_id = p.product_id
        WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
            AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
            AND creation_time BETWEEN '2022-08-26' AND '2022-09-08 23:59:59') t
    GROUP BY weekday, weekday_number
),
number_of_users AS (
    SELECT
        to_char(time::date, 'Day') AS weekday,
        CASE
            WHEN DATE_PART('dow', time::date) = 0.0 THEN 7.0
            ELSE DATE_PART('dow', time::date)
        END AS weekday_number,
        COUNT(DISTINCT user_id) AS total_users,
        COUNT(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order') AND action = 'create_order') AS paying_users
    FROM user_actions
    WHERE time BETWEEN '2022-08-26' AND '2022-09-08 23:59:59'
    GROUP BY weekday, weekday_number
),

number_of_orders AS (
    SELECT
        to_char(creation_time::date, 'Day') AS weekday,
        CASE
            WHEN DATE_PART('dow', creation_time::date) = 0.0 THEN 7.0
            ELSE DATE_PART('dow', creation_time::date)
        END AS weekday_number,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order') 
        AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
        AND creation_time BETWEEN '2022-08-26' AND '2022-09-08 23:59:59'
    GROUP BY weekday, weekday_number
)

SELECT
    r.weekday,
    r.weekday_number,
    ROUND(revenue / total_users, 2) AS arpu,
    ROUND(revenue / paying_users, 2) AS arppu,
    ROUND(revenue / total_orders, 2) AS aov
FROM revenue r
    JOIN number_of_users nou
        ON r.weekday_number = nou.weekday_number
    JOIN number_of_orders noo
        ON r.weekday_number = noo.weekday_number
ORDER BY weekday_number
