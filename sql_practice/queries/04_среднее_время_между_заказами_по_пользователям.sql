-- Redash query ID: 136811
-- Name: среднее_время_между_заказами_по_пользователям

-- На основе запроса из предыдущего задания для каждого пользователя рассчитайте, сколько в среднем времени проходит между его заказами. 
-- Посчитайте этот показатель только для тех пользователей, которые за всё время оформили более одного неотмененного заказа.

-- Среднее время между заказами выразите в часах, округлив значения до целого числа. Колонку со средним значением времени назовите hours_between_orders. 
-- Результат отсортируйте по возрастанию id пользователя.

-- Добавьте в запрос оператор LIMIT и включите в результат только первые 1000 записей.

-- Поля в результирующей таблице: user_id, hours_between_orders

SELECT 
    DISTINCT t.user_id,
    (AVG(t.time_diff) OVER(PARTITION BY user_id))::int AS hours_between_orders
FROM (SELECT 
        user_id,
        order_id,
        time,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) AS order_number,
        (EXTRACT(epoch FROM AGE(time, LAG(time) OVER(PARTITION BY user_id ORDER BY time))) / 3600) AS time_diff,
        COUNT(order_id) OVER(PARTITION BY user_id) AS order_counts
    FROM user_actions 
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    ORDER BY user_id, order_id) t
WHERE t.order_counts > 1
ORDER BY user_id
LIMIT 1000
