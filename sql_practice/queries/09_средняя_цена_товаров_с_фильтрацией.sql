-- Redash query ID: 136835
-- Name: средняя_цена_товаров_с_фильтрацией

-- Примените оконную функцию к таблице products и с помощью агрегирующей функции в отдельной колонке для каждой записи проставьте среднюю цену всех товаров.
-- Колонку с этим значением назовите avg_price.

-- Затем с помощью оконной функции и оператора FILTER в отдельной колонке рассчитайте среднюю цену товаров без учёта самого дорогого. Колонку с этим средним
-- значением назовите avg_price_filtered. Полученные средние значения в колонках avg_price и avg_price_filtered округлите до двух знаков после запятой.

-- Выведите всю информацию о товарах, включая значения в новых колонках. Результат отсортируйте сначала по убыванию цены товара, затем по возрастанию id товара.

-- Поля в результирующей таблице: product_id, name, price, avg_price, avg_price_filtered

SELECT
    product_id,
    name,
    price,
    ROUND(AVG(price) OVER(), 2) AS avg_price,
    ROUND(AVG(price) FILTER(WHERE price < (SELECT MAX(price) FROM products)) OVER(), 2) AS avg_price_filtered
FROM products
ORDER BY price DESC, product_id
