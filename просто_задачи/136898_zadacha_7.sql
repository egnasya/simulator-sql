-- Redash query ID: 136898
-- Name: zadacha 7

SELECT date, AVG(minutes_to_deliv)::INT as minutes_to_deliver
FROM(
SELECT MAX(time)::DATE as date, order_id, EXTRACT(EPOCH FROM MAX(time)) AS time_deliver, EXTRACT(EPOCH FROM MIN(time)) AS time_accept, 
(EXTRACT(EPOCH FROM MAX(time)) - EXTRACT(EPOCH FROM MIN(time)))/60.0 as minutes_to_deliv
FROM courier_actions
WHERE action = 'deliver_order' OR (action = 'accept_order' AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order'))
GROUP BY order_id) t
GROUP BY date
ORDER BY date







WHERE action = 'deliver_order' OR (action = 'accept_order' AND order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order'))



SELECT * 
FROM courier_actions

EXTRACT(epoch FROM INTERVAL '3 days, 1:21:32')

WITH  t1 as (SELECT time::DATE as date, COUNT(DISTINCT user_id) as payning_users, COUNT(DISTINCT order_id) as order_cou
FROM user_actions
WHERE action = 'create_order' and order_id NOT IN (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
GROUP BY date),
