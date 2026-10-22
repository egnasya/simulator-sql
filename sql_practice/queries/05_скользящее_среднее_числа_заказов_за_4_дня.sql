-- Redash query ID: 136820
-- Name: скользящее_среднее_числа_заказов_за_4_дня

-- Сначала на основе таблицы orders сформируйте новую таблицу с общим числом заказов по дням. Вы уже делали это в одной из предыдущих задач. 
-- При подсчёте числа заказов не учитывайте отменённые заказы (их можно определить по таблице user_actions). Колонку с числом заказов назовите orders_count.

-- Затем поместите полученную таблицу в подзапрос и примените к ней оконную функцию в паре с агрегирующей функцией AVG для расчёта скользящего среднего 
-- числа заказов. Скользящее среднее для каждой записи считайте по трём предыдущим дням. Подумайте, как правильно задать границы рамки, чтобы получить 
-- корректные расчёты.

-- Полученные значения скользящего среднего округлите до двух знаков после запятой. Колонку с рассчитанным показателем назовите moving_avg. 
-- Сортировку результирующей таблицы делать не нужно.

-- Поля в результирующей таблице: date, orders_count, moving_avg

SELECT 
    date,
    orders_count,
    LAG(moving_avg) OVER() AS moving_avg
FROM
    (SELECT
        creation_time::date AS date,
        COUNT(order_id) AS orders_count,
        ROUND(AVG(COUNT(order_id)) OVER(ORDER BY creation_time::date ROWS BETWEEN 2 PRECEDING AND 0 FOLLOWING), 2) AS moving_avg
    FROM orders
    WHERE order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
    GROUP BY date) od
