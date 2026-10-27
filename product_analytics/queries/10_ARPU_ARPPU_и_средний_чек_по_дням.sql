-- Redash query ID: 137159
-- Name: ARPU_ARPPU_и_средний_чек_по_дням

-- Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:
--  - Выручку на пользователя (ARPU) за текущий день.
--  - Выручку на платящего пользователя (ARPPU) за текущий день.
--  - Выручку с заказа, или средний чек (AOV) за текущий день.
-- При расчёте всех показателей округляйте значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты. 
-- Поля в результирующей таблице: date, arpu, arppu, aov

WITH revenue_metrics AS (
    SELECT
        date,
        revenue,
        avg_order_value,
        SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_revenue,
        ROUND((revenue::decimal - LAG(revenue) OVER(ORDER BY date)) / LAG(revenue) OVER(ORDER BY date) * 100, 2) AS revenue_change
    FROM (    
        SELECT
            creation_time::date AS date,
            SUM(price) AS revenue,
            ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
        FROM orders o
            CROSS JOIN LATERAL unnest(o.product_ids) AS pl(product_id)
            JOIN products p ON p.product_id = pl.product_id
        WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order') 
            AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        GROUP BY 1
        ) t
    GROUP BY date, revenue, avg_order_value
),

number_of_uers AS (
    SELECT
        time::date AS date,
        count(DISTINCT user_id) AS total_users,
        count(DISTINCT user_id) FILTER(WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS paying_users
    FROM user_actions
    GROUP BY 1
)

SELECT
    creation_time:: date AS date,
    ROUND(revenue / total_users, 2) AS arpu,
    ROUND(revenue / paying_users, 2) AS arppu,
    avg_order_value AS aov
FROM orders o
    JOIN revenue_metrics rm ON rm.date = o.creation_time::date
    JOIN number_of_uers nou ON nou.date = o.creation_time::date
GROUP BY
     1, 2, 3, 4
