-- Redash query ID: 136893
-- Name: New Query

-- Отберите из таблицы products все товары, названия которых либо начинаются со слова «чай», либо состоят из пяти символов. Выведите две колонки: id товаров и их наименования.
-- Результат должен быть отсортирован по возрастанию id товара.
-- Поля в результирующей таблице: product_id, name
-- Для решения задачи вам пригодятся функции SPLIT_PART и LENGTH, которые мы рассматривали на прошлом уроке.

SELECT 
    product_id,
    name, 
    price AS old_price,
    price*0.8 AS new_price
FROM products
WHERE price*0.8 > 100
ORDER BY product_id
