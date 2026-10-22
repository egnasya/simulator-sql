-- Redash query ID: 136823
-- Name: курьеры_выше_среднего_по_доставкам_за_сентябрь

-- Отметьте в отдельной таблице тех курьеров, которые доставили в сентябре 2022 года заказов больше, чем в среднем все курьеры.

-- Сначала для каждого курьера в таблице courier_actions рассчитайте общее количество доставленных в сентябре заказов. 
-- Затем в отдельном столбце с помощью оконной функции укажите, сколько в среднем заказов доставили в этом месяце все курьеры. 
-- После этого сравните число заказов, доставленных каждым курьером, со средним значением в новом столбце. Если курьер доставил больше заказов, 
-- чем в среднем все курьеры, то в отдельном столбце с помощью CASE укажите число 1, в противном случае укажите 0.

-- Колонку с результатом сравнения назовите is_above_avg, колонку с числом доставленных заказов каждым курьером — delivered_orders, 
-- а колонку со средним значением — avg_delivered_orders. При расчёте среднего значения округлите его до двух знаков после запятой. 
-- Результат отсортируйте по возрастанию id курьера.

-- Поля в результирующей таблице: courier_id, delivered_orders, avg_delivered_orders, is_above_avg

SELECT
    courier_id,
    COUNT(DISTINCT order_id) AS delivered_orders,
    ROUND(AVG(COUNT(DISTINCT order_id)) OVER(), 2) AS avg_delivered_orders,
    CASE
        WHEN COUNT(DISTINCT order_id) > ROUND(AVG(COUNT(DISTINCT order_id)) OVER(), 2) THEN 1
        ELSE 0
    END AS is_above_avg
FROM courier_actions
WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order') 
    AND time BETWEEN '2022-09-01' AND '2022-09-30 23:59:59'
GROUP BY courier_id
ORDER BY courier_id
