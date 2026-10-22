-- Redash query ID: 136752
-- Name: списки_названий_товаров_по_заказам

-- Произведите замену списков с id товаров из таблицы orders на списки с наименованиями товаров. Наименования возьмите из таблицы products. 
-- Колонку с новыми списками наименований назовите product_names. 

-- Добавьте в запрос оператор LIMIT и выведите только первые 1000 строк результирующей таблицы.

-- Сортировать список не нужно.

-- Поля в результирующей таблице: order_id, product_names

SELECT 
  op.order_id,
  array_agg(p.name) AS product_names
FROM (SELECT 
        order_id,
        unnest(product_ids) AS product_id
    FROM orders) op
    LEFT JOIN products p
    ON op.product_id = p.product_id
GROUP BY op.order_id
LIMIT 1000
