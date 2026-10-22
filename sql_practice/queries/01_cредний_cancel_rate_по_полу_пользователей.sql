-- Redash query ID: 136742
-- Name: cредний_cancel_rate_по_полу_пользователей

-- Возьмите запрос, составленный на одном из прошлых уроков, и подтяните в него из таблицы users данные о поле пользователей таким образом, 
-- чтобы все пользователи из таблицы user_actions остались в результате. Затем посчитайте среднее значение cancel_rate для каждого пола, 
-- округлив его до трёх знаков после запятой. Колонку с посчитанным средним значением назовите avg_cancel_rate.

-- Помните про отсутствие информации о поле некоторых пользователей после join, так как не все пользователи из таблицы user_action есть в таблице users. 
-- Для этой группы тоже посчитайте cancel_rate и в результирующей таблице для пустого значения в колонке с полом укажите ‘unknown’ (без кавычек). 
-- Возможно, для этого придётся вспомнить, как работает COALESCE.

-- Результат отсортируйте по колонке с полом пользователя по возрастанию.

-- Поля в результирующей таблице: sex, avg_cancel_rate

WITH cancel_rate_per_users AS ( 
    SELECT
        user_id,
        ROUND(COUNT(order_id) FILTER(WHERE action = 'cancel_order') / (COUNT(order_id) FILTER(WHERE action = 'create_order'))::DECIMAL, 3) AS cancel_rate
    FROM
        user_actions
    GROUP BY
        user_id
)
SELECT
  COALESCE(u.sex, 'unknown') AS sex,
  ROUND(AVG(cru.cancel_rate)::DECIMAL, 3) AS avg_cancel_rate
FROM
  users u
  RIGHT JOIN cancel_rate_per_users cru
  ON cru.user_id = u.user_id
GROUP BY
  u.sex
ORDER BY 
  u.sex
