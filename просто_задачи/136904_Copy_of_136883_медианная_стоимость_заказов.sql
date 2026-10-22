-- Redash query ID: 136904
-- Name: Copy of (#136883) медианная_стоимость_заказов

-- С помощью оконной функции рассчитайте медианную стоимость всех заказов из таблицы orders, оформленных в нашем сервисе.
-- В качестве результата выведите одно число. Колонку с ним назовите median_price. Отменённые заказы не учитывайте.
-- Поле в результирующей таблице: median_price

WITH ranged_list_products_prices AS (
  SELECT
    order_id,
    SUM(price) AS order_price,
    ROW_NUMBER() OVER(
      ORDER BY
        SUM(price)
    ) AS row_number
  FROM
    (
      SELECT
        order_id,
        unnest(product_ids) AS product_id
      FROM
        orders
    ) op
    LEFT JOIN products p ON p.product_id = op.product_id
  GROUP BY
    order_id
)
SELECT
  AVG(order_price) AS median_price
FROM
  ranged_list_products_prices
WHERE
  row_number BETWEEN (
    SELECT
      CASE
        WHEN MAX(row_number) % 2 = 0 THEN MAX(row_number) / 2
        ELSE CEIL(MAX(row_number) / 2.0) :: int
      END
    FROM
      ranged_list_products_prices
  )
  AND (
    SELECT
      CASE
        WHEN MAX(row_number) % 2 = 0 THEN MAX(row_number) / 2 + 1
        ELSE CEIL(MAX(row_number) / 2.0) :: int
      END AS median_row
    FROM
      ranged_list_products_prices
  )
