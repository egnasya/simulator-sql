-- Redash query ID: 136897
-- Name: New Query

SELECT
name, UPPER(SPLIT_PART(name,' ',1)) AS first_word, price
FROM
  products
ORDER BY
  name ASC
