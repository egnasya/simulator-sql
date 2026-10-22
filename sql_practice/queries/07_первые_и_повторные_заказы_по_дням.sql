-- Redash query ID: 136826
-- Name: первые_и_повторные_заказы_по_дням

-- По данным таблицы user_actions посчитайте число первых и повторных заказов на каждую дату.

-- Для этого сначала с помощью оконных функций и оператора CASE сформируйте таблицу, в которой напротив каждого заказа будет стоять отметка 
-- «Первый» или «Повторный» (без кавычек). Для каждого пользователя первым заказом будет тот, который был сделан раньше всего. Все остальные заказы 
-- должны попасть, соответственно, в категорию «Повторный». Затем на каждую дату посчитайте число заказов каждой категории.

-- Колонку с типом заказа назовите order_type, колонку с датой — date, колонку с числом заказов — orders_count.

-- В расчётах учитывайте только неотменённые заказы.

-- Результат отсортируйте сначала по возрастанию даты, затем по возрастанию значений в колонке с типом заказа.

-- Поля в результирующей таблице: date, order_type, orders_count

SELECT date, order_type, COUNT(orders_count) AS orders_count
FROM
    (SELECT
        time::date AS date,
        CASE
            WHEN ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY time) = 1 THEN 'Первый'
            ELSE 'Повторный'
        END AS order_type,
        COUNT(order_id) AS orders_count
    FROM user_actions
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY date, time, order_id, user_id) o
GROUP BY order_type, date
ORDER BY date, order_type
