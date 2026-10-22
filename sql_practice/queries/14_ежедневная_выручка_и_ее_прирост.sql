-- Redash query ID: 136875
-- Name: ежедневная_выручка_и_ее_прирост

-- На основе информации в таблицах orders и products рассчитайте ежедневную выручку сервиса и отразите её в колонке daily_revenue. Затем 
-- с помощью оконных функций и функций смещения посчитайте ежедневный прирост выручки. Прирост выручки отразите как в абсолютных значениях, 
-- так и в % относительно предыдущего дня. Колонку с абсолютным приростом назовите revenue_growth_abs, а колонку с относительным — revenue_growth_percentage.

-- Для самого первого дня укажите прирост равным 0 в обеих колонках. При проведении расчётов отменённые заказы не учитывайте. 
-- Результат отсортируйте по колонке с датами по возрастанию.

-- Метрики daily_revenue, revenue_growth_abs, revenue_growth_percentage округлите до одного знака при помощи ROUND().

-- Поля в результирующей таблице: date, daily_revenue, revenue_growth_abs, revenue_growth_percentage

SELECT *,
    CASE 
        WHEN daily_revenue - LAG(daily_revenue) OVER(ORDER BY date) IS NOT NULL THEN daily_revenue - LAG(daily_revenue) OVER(ORDER BY date)
        ELSE 0
    END AS revenue_growth_abs,
    CASE 
        WHEN daily_revenue - LAG(daily_revenue) OVER(ORDER BY date) IS NOT NULL THEN ROUND((daily_revenue - LAG(daily_revenue) OVER(ORDER BY date)) / LAG(daily_revenue) OVER(ORDER BY date) * 100, 1) 
        ELSE 0
    END AS revenue_growth_percentage
FROM (SELECT 
    DISTINCT opl.creation_time::date AS date,
    SUM(p.price) OVER(PARTITION BY opl.creation_time::date) AS daily_revenue
FROM (SELECT 
        order_id,
        creation_time,
        unnest(product_ids) AS product_id
    FROM orders) opl
    LEFT JOIN products p
    ON opl.product_id = p.product_id
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) t
ORDER BY date
