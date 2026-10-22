-- Redash query ID: 136831
-- Name: доля_первых_и_повторных_заказов_по_дням

-- К запросу, полученному на предыдущем шаге, примените оконную функцию и для каждого дня посчитайте долю первых и повторных заказов. 
-- Сохраните структуру полученной ранее таблицы и добавьте только одну новую колонку с посчитанными значениями.

-- Колонку с долей заказов каждой категории назовите orders_share. Значения в полученном столбце округлите до двух знаков после запятой. 
-- В результат также включите количество заказов в группах, посчитанное на предыдущем шаге.

-- В расчётах по-прежнему учитывайте только неотменённые заказы.

-- Результат отсортируйте сначала по возрастанию даты, затем по возрастанию значений в колонке с типом заказа.

-- Поля в результирующей таблице: date, order_type, orders_count, orders_share

SELECT 
    date, 
    order_type, 
    COUNT(orders_count) AS orders_count,
    ROUND(COUNT(orders_count) / SUM(COUNT(orders_count)) OVER(PARTITION BY date), 2) AS orders_share
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
