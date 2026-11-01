-- Redash query ID: 137579
-- Name: выручка_затраты_и_валовая_прибыл

-- Для каждого дня в таблицах orders и courier_actions рассчитайте следующие показатели:
--  - Выручку, полученную в этот день.
--  - Затраты, образовавшиеся в этот день.
--  - Сумму НДС с продажи товаров в этот день.
--  - Валовую прибыль в этот день (выручка за вычетом затрат и НДС).
--  - Суммарную выручку на текущий день.
--  - Суммарные затраты на текущий день.
--  - Суммарный НДС на текущий день.
--  - Суммарную валовую прибыль на текущий день.
--  - Долю валовой прибыли в выручке за этот день (долю п.4 в п.1).
--  - Долю суммарной валовой прибыли в суммарной выручке на текущий день (долю п.8 в п.5).
-- Долю валовой прибыли в выручке необходимо выразить в процентах, округлив значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, revenue, costs, tax, gross_profit, total_revenue, total_costs, total_tax, total_gross_profit, gross_profit_ratio,total_gross_profit_ratio

-- august_2022 = 120 000
-- september_2022 = 150 000

-- expenses_per_order_aug22 = 140
-- expenses_per_courier_aug22 = 150
-- expenses_per_courier_aug22 = 400 (orders_per_courier >= 5)

-- expenses_per_order_sep22 = 115
-- expenses_per_courier_sep22 = 150
-- expenses_per_courier_sep22 = 500 (orders_per_courier >= 5)

WITH expenses AS (
    SELECT
        c.date,
        SUM(expenses_per_courier) AS expenses_per_courier,
        expenses_per_order,
        CASE
            WHEN DATE_PART('month', c.date) = 8.0 THEN 120000.0
            ELSE 150000 * 1.0
        END AS fixed_costs
    FROM (
        SELECT
            time::date AS date,
            courier_id,
            COUNT(DISTINCT order_id) AS number_of_orders,
            CASE
                WHEN COUNT(DISTINCT order_id) < 5 THEN COUNT(DISTINCT order_id) * 150
                WHEN COUNT(DISTINCT order_id) >= 5 AND DATE_PART('month', time::date) = 9.0 THEN COUNT(DISTINCT order_id) * 150 + 500
                ELSE COUNT(DISTINCT order_id) * 150 + 400
            END AS expenses_per_courier
        FROM courier_actions
        WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order') AND action = 'deliver_order'
        GROUP BY date, courier_id
    ) c
    JOIN (
        SELECT
            creation_time::date AS date,
            COUNT(DISTINCT order_id) AS number_of_orders,
            CASE
                WHEN DATE_PART('month', creation_time::date) = 8.0 THEN COUNT(DISTINCT order_id) * 140
                ELSE COUNT(DISTINCT order_id) * 115
            END AS expenses_per_order
        FROM orders
        WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
        GROUP BY date
    ) o 
    ON c.date = o.date
    GROUP BY c.date, expenses_per_order
),

revenue AS (
    SELECT
        creation_time::date AS date,
        SUM(price) AS revenue
    FROM orders o
        CROSS JOIN LATERAL unnest(product_ids) AS pl(product_id)
        JOIN products p ON p.product_id = pl.product_id
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
        AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY date
),

taxes AS (
    SELECT
        product_id,
        name,
        price,
        CASE
            WHEN name IN ('сахар', 'сухарики', 'сушки', 'семечки', 
                          'масло льняное', 'виноград', 'масло оливковое', 
                          'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
                          'овсянка', 'макароны', 'баранина', 'апельсины', 
                          'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
                          'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
                          'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
                          'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
                          'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') 
            THEN ROUND(price * 10 / 110, 2)  
            ELSE ROUND(price * 20 / 120, 2)  
        END AS tax
    FROM products
),

taxes_per_day AS (
    SELECT
        creation_time::date AS date,
        SUM(tax) AS tax
    FROM orders o
        CROSS JOIN LATERAL unnest(product_ids) AS pl(product_id)
        JOIN taxes t ON t.product_id = pl.product_id
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
        AND order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY creation_time::date
)

SELECT
    r.date,
    revenue,
    expenses_per_order + expenses_per_courier + fixed_costs AS costs,
    tax,
    revenue - (expenses_per_order + expenses_per_courier + fixed_costs) - tax AS gross_profit,
    SUM(revenue) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_revenue,
    SUM(expenses_per_order + expenses_per_courier + fixed_costs) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_costs,
    SUM(tax) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_tax,
    SUM(revenue - (expenses_per_order + expenses_per_courier + fixed_costs) - tax) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_gross_profit,
    ROUND((revenue - (expenses_per_order + expenses_per_courier + fixed_costs) - tax) / revenue * 100, 2) AS gross_profit_ratio,
    ROUND(SUM(revenue - (expenses_per_order + expenses_per_courier + fixed_costs) - tax) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / 
        SUM(revenue) OVER(ORDER BY r.date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100, 2) AS total_gross_profit_ratio
FROM revenue r
    JOIN expenses e ON r.date = e.date
    JOIN taxes_per_day t ON r.date = t.date
