-- Redash query ID: 137545
-- Name: выручка_новых_и_старых_пользователей_по_дням

-- Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:
--  - Выручку, полученную в этот день.
--  - Выручку с заказов новых пользователей, полученную в этот день.
--  - Долю выручки с заказов новых пользователей в общей выручке, полученной за этот день.
--  - Долю выручки с заказов остальных пользователей в общей выручке, полученной за этот день.
-- Все показатели долей необходимо выразить в процентах. При их расчёте округляйте значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, revenue, new_users_revenue, new_users_revenue_share, old_users_revenue_share

WITH user_cohorts AS (
    SELECT
        DISTINCT ua.time::date AS date,
        ua.user_id, 
        CASE
            WHEN first_day != ua.time::date THEN false
            ELSE true
        END AS is_first_day
    FROM user_actions ua
        JOIN (SELECT user_id, MIN(time::date) AS first_day FROM user_actions GROUP BY user_id) ud ON ua.user_id = ud.user_id
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
),

revenue AS ( 
    SELECT 
        creation_time::date AS date,
        ua.user_id,
        is_first_day,
        price
    FROM orders o
        CROSS JOIN LATERAL unnest(product_ids) AS pl(product_id)
        JOIN products p ON p.product_id = pl.product_id
        JOIN user_actions ua ON ua.order_id = o.order_id
        JOIN user_cohorts uc ON uc.user_id = ua.user_id AND uc.date = o.creation_time::date
    WHERE o.order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        AND o.order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
)

SELECT
    r.date,
    SUM(price) AS revenue,
    SUM(price) FILTER(WHERE is_first_day = true) AS new_users_revenue,
    ROUND(SUM(price) FILTER(WHERE is_first_day = true) / SUM(price) * 100, 2) AS new_users_revenue_share,
    COALESCE(ROUND(SUM(price) FILTER(WHERE is_first_day = false) / SUM(price) * 100, 2), 0.0) AS old_users_revenue_share
FROM revenue r
GROUP BY r.date
