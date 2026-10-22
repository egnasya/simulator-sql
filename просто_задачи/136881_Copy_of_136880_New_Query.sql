-- Redash query ID: 136881
-- Name: Copy of (#136880) New Query

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
