-- Redash query ID: 136880
-- Name: Cамый дорогой товар

SELECT
  name,
  LENGTH(name) as name_length,
  price
FROM
  products
ORDER BY
  name_length desc
limit
  1
