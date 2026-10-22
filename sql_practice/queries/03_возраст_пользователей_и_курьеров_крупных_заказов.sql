-- Redash query ID: 136757
-- Name: возраст_пользователей_и_курьеров_крупных_заказов

-- Выясните, кто заказывал и доставлял самые большие заказы. Самыми большими считайте заказы с наибольшим числом товаров.

-- Выведите id заказа, id пользователя и id курьера. Также в отдельных колонках укажите возраст пользователя и возраст курьера. 
-- Возраст измерьте числом полных лет, как мы делали в прошлых уроках. Считайте его относительно последней даты в таблице user_actions — как для пользователей, 
-- так и для курьеров. Колонки с возрастом назовите user_age и courier_age. Результат отсортируйте по возрастанию id заказа.

-- Поля в результирующей таблице: order_id, user_id, user_age, courier_id, courier_age

WITH count_products AS (
    SELECT order_id, array_length(product_ids, 1) AS products_count 
    FROM orders 
    ORDER BY products_count DESC 
)
SELECT
    DISTINCT pc.order_id,
    ua.user_id,
    DATE_PART('year', AGE((SELECT MAX(time) FROM user_actions), u.birth_date))::int AS user_age,
    ca.courier_id,
    DATE_PART('year', AGE((SELECT MAX(time) FROM user_actions), c.birth_date))::int AS courier_age
FROM (SELECT order_id, array_length(product_ids, 1) AS products_count FROM orders ORDER BY products_count DESC) pc
    LEFT JOIN user_actions ua
    ON ua.order_id = pc.order_id
    LEFT JOIN users u 
    ON u.user_id = ua.user_id
    LEFT JOIN courier_actions ca
    ON ca.order_id = pc.order_id
    LEFT JOIN couriers c
    ON c.courier_id = ca.courier_id
WHERE pc.order_id IN (SELECT order_id FROM count_products WHERE products_count = (SELECT products_count FROM count_products LIMIT 1))
ORDER BY pc.order_id
