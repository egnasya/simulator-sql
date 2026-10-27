-- Redash query ID: 137158
-- Name: ежедневная_выручка_накопительная_выручка_и_её_прирост

-- Для каждого дня в таблице orders рассчитайте следующие показатели:
--  - Выручку, полученную в этот день.
--  - Суммарную выручку на текущий день.
--  - Прирост выручки, полученной в этот день, относительно значения выручки за предыдущий день.
-- Прирост выручки рассчитайте в процентах и округлите значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, revenue, total_revenue, revenue_change

SELECT
    date,
    revenue,
    SUM(revenue) OVER(ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_revenue,
    ROUND((revenue::decimal - LAG(revenue) OVER(ORDER BY date)) / LAG(revenue) OVER(ORDER BY date) * 100, 2) AS revenue_change
FROM (    
    SELECT
        creation_time::date AS date,
        SUM(price) AS revenue
    FROM orders o
        CROSS JOIN LATERAL unnest(o.product_ids) AS pl(product_id)
        JOIN products p ON p.product_id = pl.product_id
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order') 
        AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY 1
    ) t
GROUP BY date, revenue
