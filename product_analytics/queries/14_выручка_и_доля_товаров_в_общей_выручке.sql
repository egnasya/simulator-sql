-- Redash query ID: 137547
-- Name: выручка_и_доля_товаров_в_общей_выручке

-- Для каждого товара, представленного в таблице products, за весь период времени в таблице orders рассчитайте следующие показатели:
--  - Суммарную выручку, полученную от продажи этого товара за весь период.
--  - Долю выручки от продажи этого товара в общей выручке, полученной за весь период.
-- Долю выручки с каждого товара необходимо выразить в процентах. При её расчёте округляйте значения до двух знаков после запятой. Товары, округлённая доля которых в выручке 
-- составляет менее 0.5%, объедините в общую группу с названием «ДРУГОЕ» (без кавычек), просуммировав округлённые доли этих товаров. Результат должен быть отсортирован 
-- по убыванию выручки от продажи товара.
-- Поля в результирующей таблице: product_name, revenue, share_in_revenue

WITH revenue_by_products AS ( 
    SELECT 
        DISTINCT p.name AS product_name,
        SUM(price) OVER(PARTITION BY pl.product_id) AS revenue_by_products,
        SUM(price) OVER() AS revenue
    FROM orders o
        CROSS JOIN LATERAL unnest(product_ids) AS pl(product_id)
        JOIN products p ON p.product_id = pl.product_id
    WHERE o.order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        AND o.order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
)

SELECT
    product_name,
    SUM(revenue) AS revenue,
    SUM(share_in_revenue) AS share_in_revenue
FROM (SELECT
    CASE
        WHEN ROUND(revenue_by_products / revenue * 100, 2) < 0.5 THEN 'ДРУГОЕ'
        ELSE product_name
    END AS product_name,
    revenue_by_products AS revenue,
    ROUND(revenue_by_products / revenue * 100, 2) AS share_in_revenue
FROM revenue_by_products) t
GROUP BY product_name
ORDER BY revenue DESC
