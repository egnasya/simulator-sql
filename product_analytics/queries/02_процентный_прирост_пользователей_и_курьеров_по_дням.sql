-- Redash query ID: 136954
-- Name: процентный_прирост_пользователей_и_курьеров_по_дням

-- Дополните запрос из предыдущего задания и теперь для каждого дня, представленного в таблицах user_actions и courier_actions, дополнительно рассчитайте следующие показатели:
--  - Прирост числа новых пользователей.
--  - Прирост числа новых курьеров.
--  - Прирост общего числа пользователей.
--  - Прирост общего числа курьеров.
-- Показатели, рассчитанные на предыдущем шаге, также включите в результирующую таблицу.
-- Все показатели прироста считайте в процентах относительно значений в предыдущий день. При расчёте показателей округляйте значения до двух знаков после запятой.
-- Результирующая таблица должна быть отсортирована по возрастанию даты.
-- Поля в результирующей таблице: date, new_users, new_couriers, total_users, total_couriers, new_users_change, new_couriers_change, total_users_growth, total_couriers_growth

WITH date_list AS (
  SELECT
    ua.time :: date AS date
  FROM
    user_actions ua
  UNION
  SELECT
    ca.time :: date AS date
  FROM
    courier_actions ca
  ORDER BY
    date
),

numbered_users AS (
  SELECT
    time :: date AS date,
    user_id,
    order_id,
    ROW_NUMBER() OVER(
      PARTITION BY user_id
      ORDER BY
        time
    ) AS user_order_number
  FROM
    user_actions
),

numbered_couriers AS (
  SELECT
    time :: date AS date,
    courier_id,
    order_id,
    ROW_NUMBER() OVER(
      PARTITION BY courier_id
      ORDER BY
        time
    ) AS courier_order_number
  FROM
    courier_actions
),

new_users AS (
    SELECT date, COUNT(user_id) AS new_users
    FROM numbered_users
    WHERE user_order_number = 1
    GROUP BY date
),

new_couriers AS (
    SELECT date, COUNT(courier_id) AS new_couriers
    FROM numbered_couriers
    WHERE courier_order_number = 1
    GROUP BY date
),

daily_users AS (
    SELECT
        date,
        SUM(new_users) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_users
    FROM new_users
),

daily_couriers AS (
    SELECT
        date,
        SUM(new_couriers) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_couriers
    FROM new_couriers
)


SELECT
  dl.date,
  COALESCE(new_users, 0) AS new_users,
  COALESCE(new_couriers, 0) AS new_couriers,
  total_users::int,
  total_couriers::int,
  ROUND((new_users::numeric - LAG(new_users) OVER()) / LAG(new_users) OVER() * 100, 2) AS new_users_change,
  ROUND((new_couriers::numeric - LAG(new_couriers) OVER()) / LAG(new_couriers) OVER() * 100, 2) AS new_couriers_change,
  ROUND((total_users::numeric - LAG(total_users) OVER()) / (LAG(total_users) OVER()) * 100, 2) AS total_users_growth,
  ROUND((total_couriers::numeric - LAG(total_couriers) OVER()) / (LAG(total_couriers) OVER()) * 100, 2) AS total_couriers_growth
FROM
  date_list dl
  LEFT JOIN new_users nu ON dl.date = nu.date
  LEFT JOIN new_couriers nc ON dl.date = nc.date
  LEFT JOIN daily_users du ON dl.date = du.date
  LEFT JOIN daily_couriers dc ON dl.date = dc.date
ORDER BY dl.date
