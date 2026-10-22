-- Redash query ID: 136888
-- Name: New Query

SELECT
  CONCAT(
    'Заказ №',
    product_ids,
    ' создан ',
    creation_time :: DATE
  ) AS order_info
FROM
  orders
ORDER BY
  product_ids
LIMIT
  200
