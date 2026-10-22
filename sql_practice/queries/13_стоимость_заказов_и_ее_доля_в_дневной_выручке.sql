-- Redash query ID: 136873
-- Name: стоимость_заказов_и_ее_доля_в_дневной_выручке

-- На основе информации в таблицах orders и products рассчитайте стоимость каждого заказа, ежедневную выручку сервиса и долю стоимости каждого заказа 
-- в ежедневной выручке, выраженную в процентах. В результат включите следующие колонки: id заказа, время создания заказа, стоимость заказа, выручку за день, 
-- в который был совершён заказ, а также долю стоимости заказа в выручке за день, выраженную в процентах.

-- При расчёте долей округляйте их до трёх знаков после запятой.

-- Результат отсортируйте сначала по убыванию даты совершения заказа (именно даты, а не времени), потом по убыванию доли заказа в выручке за день, 
-- затем по возрастанию id заказа.

-- При проведении расчётов отменённые заказы не учитывайте.

-- Поля в результирующей таблице: order_id, creation_time, order_price, daily_revenue, percentage_of_daily_revenue

SELECT *    
FROM (SELECT 
    DISTINCT opl.order_id,
    opl.creation_time,
    SUM(p.price) OVER(PARTITION BY opl.order_id) AS order_price,
    SUM(p.price) OVER(PARTITION BY opl.creation_time::date) AS daily_revenue,
    ROUND(SUM(p.price) OVER(PARTITION BY opl.order_id) / SUM(p.price) OVER(PARTITION BY opl.creation_time::date) * 100, 3) AS percentage_of_daily_revenue
FROM (SELECT 
        order_id,
        creation_time,
        unnest(product_ids) AS product_id
    FROM orders) opl
    LEFT JOIN products p
    ON opl.product_id = p.product_id
WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) t
ORDER BY creation_time::date DESC, 5 DESC, 1
