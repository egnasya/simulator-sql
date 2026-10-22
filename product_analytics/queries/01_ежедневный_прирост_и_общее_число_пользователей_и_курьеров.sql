-- Redash query ID: 136948
-- Name: ежедневный_прирост_и_общее_число_пользователей_и_курьеров

-- Для каждого дня, представленного в таблицах user_actions и courier_actions, рассчитайте следующие показатели:
--  - Число новых пользователей.
--  - Число новых курьеров.
--  - Общее число пользователей на текущий день.
--  - Общее число курьеров на текущий день.
-- Колонки с показателями назовите соответственно new_users, new_couriers, total_users, total_couriers. Колонку с датами назовите date.
-- Проследите за тем, чтобы показатели были выражены целыми числами. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, new_users, new_couriers, total_users, total_couriers

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
  total_users::int,
  COALESCE(new_couriers, 0) AS new_couriers,
  total_couriers::int
FROM
  date_list dl
  LEFT JOIN new_users nu ON dl.date = nu.date
  LEFT JOIN new_couriers nc ON dl.date = nc.date
  LEFT JOIN daily_users du ON dl.date = du.date
  LEFT JOIN daily_couriers dc ON dl.date = dc.date
ORDER BY dl.date
