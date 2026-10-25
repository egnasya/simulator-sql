-- Redash query ID: 137135
-- Name: среднее_время_доставки_заказов_по_дням

-- На основе данных в таблице courier_actions для каждого дня рассчитайте, за сколько минут в среднем курьеры доставляли свои заказы. 
-- При расчёте среднего времени доставки округляйте количество минут до целых значений. Учитывайте только доставленные заказы, отменённые заказы не учитывайте. 
-- Результирующая таблица должна быть отсортирована по возрастанию даты.
-- Поля в результирующей таблице: date, minutes_to_deliver

SELECT
    date,
    AVG(EXTRACT(epoch FROM delivery_time) / 60)::int AS minutes_to_deliver
FROM (
    SELECT
        time::date AS date,
        order_id,
        MAX(time) FILTER (WHERE action = 'deliver_order') - MIN(time) FILTER (WHERE action = 'accept_order') AS delivery_time
    FROM courier_actions
    WHERE order_id IN (SELECT order_id FROM courier_actions WHERE action = 'deliver_order')
    GROUP BY 1,2
) t
GROUP BY date
ORDER BY date
