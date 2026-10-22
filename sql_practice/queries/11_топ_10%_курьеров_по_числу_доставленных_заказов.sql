-- Redash query ID: 136854
-- Name: топ_10%_курьеров_по_числу_доставленных_заказов

-- Из таблицы courier_actions отберите топ 10% курьеров по количеству доставленных за всё время заказов. Выведите id курьеров, количество
-- доставленных заказов и порядковый номер курьера в соответствии с числом доставленных заказов.
-- У курьера, доставившего наибольшее число заказов, порядковый номер должен быть равен 1, а у курьера с наименьшим числом заказов — числу,
-- равному десяти процентам от общего количества курьеров в таблице courier_actions.
-- При расчёте номера последнего курьера округляйте значение до целого числа.
-- Колонки с количеством доставленных заказов и порядковым номером назовите соответственно orders_count и courier_rank. Результат отсортируйте
-- по возрастанию порядкового номера курьера.
-- Поля в результирующей таблице: courier_id, orders_count, courier_rank
with table1 as (
  SELECT
    courier_id,
    count(distinct order_id) as orders_count,
    row_number() OVER(
      ORDER BY
        count(order_id) desc,
        courier_id
    ) as courier_rank
  FROM
    courier_actions
  WHERE
    order_id in (
      SELECT
        order_id
      FROM
        courier_actions
      WHERE
        action = 'deliver_order'
    )
  GROUP BY
    courier_id
)
SELECT
  *
FROM
  table1
WHERE
  courier_rank <= ROUND(
    (
      SELECT
        COUNT(DISTINCT courier_id)
      FROM
        courier_actions
    ) * 0.1,
    2
  )
