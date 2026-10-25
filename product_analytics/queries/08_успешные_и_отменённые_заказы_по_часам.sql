-- Redash query ID: 137139
-- Name: успешные_и_отменённые_заказы_по_часам

-- На основе данных в таблице orders для каждого часа в сутках рассчитайте следующие показатели:
--  - Число успешных (доставленных) заказов.
--  - Число отменённых заказов.
--  - Долю отменённых заказов в общем числе заказов (cancel rate).
-- При расчёте доли отменённых заказов округляйте значения до трёх знаков после запятой. Результирующая таблица должна быть отсортирована по возрастанию колонки
-- с часом оформления заказа.
-- Поля в результирующей таблице: hour, successful_orders, canceled_orders, cancel_rate

SELECT
    DISTINCT EXTRACT(HOUR FROM creation_time)::int AS hour,
    COUNT(DISTINCT ca.order_id) FILTER(WHERE ca.order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')) AS successful_orders,
    COUNT(DISTINCT ca.order_id) FILTER(WHERE ca.order_id IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) AS canceled_orders,
    ROUND(COUNT(DISTINCT ca.order_id) FILTER(WHERE ca.order_id IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')) 
        / COUNT(DISTINCT ca.order_id)::decimal, 3) AS cancel_rate
FROM orders o 
    JOIN courier_actions ca ON o.order_id = ca.order_id
GROUP BY 1
ORDER BY 1
