-- Redash query ID: 137228
-- Name: накопительные_ARPU_ARPPU_и_средний_чек_по_дням

-- По таблицам orders и user_actions для каждого дня рассчитайте следующие показатели:
--  - Накопленную выручку на пользователя (Running ARPU).
--  - Накопленную выручку на платящего пользователя (Running ARPPU).
--  - Накопленную выручку с заказа, или средний чек (Running AOV).
-- При расчёте всех показателей округляйте значения до двух знаков после запятой. Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, running_arpu, running_arppu, running_aov
WITH dates AS (
  SELECT
    DISTINCT time :: date AS date
  FROM
    user_actions
),
first_user_date AS (
  SELECT
    user_id,
    MIN(time :: date) AS first_date
  FROM
    user_actions
  GROUP BY
    user_id
),
first_paying_user_date AS (
  SELECT
    ua.user_id,
    MIN(ua.time :: date) AS first_paid_date
  FROM
    user_actions ua
  WHERE
    ua.action = 'create_order'
    AND NOT EXISTS (
      SELECT
        1
      FROM
        user_actions canceled
      WHERE
        canceled.order_id = ua.order_id
        AND canceled.action = 'cancel_order'
    )
  GROUP BY
    ua.user_id
),
running_number_of_users AS (
  SELECT
    d.date,
    (
      SELECT
        COUNT(*)
      FROM
        first_user_date f
      WHERE
        f.first_date <= d.date
    ) AS running_total_users,
    (
      SELECT
        COUNT(*)
      FROM
        first_paying_user_date p
      WHERE
        p.first_paid_date <= d.date
    ) AS running_paying_users
  FROM
    dates d
),
order_revenue AS (
  SELECT
    o.order_id,
    o.creation_time :: date AS date,
    SUM(pr.price) AS order_revenue
  FROM
    orders o
    CROSS JOIN LATERAL unnest(o.product_ids) AS pl(product_id)
    JOIN products pr ON pr.product_id = pl.product_id
  WHERE
    EXISTS (
      SELECT
        1
      FROM
        courier_actions ca
      WHERE
        ca.order_id = o.order_id
        AND ca.action = 'deliver_order'
    )
    AND NOT EXISTS (
      SELECT
        1
      FROM
        user_actions ua
      WHERE
        ua.order_id = o.order_id
        AND ua.action = 'cancel_order'
    )
  GROUP BY
    o.order_id,
    o.creation_time :: date
),
daily_revenue AS (
  SELECT
    date,
    SUM(order_revenue) AS revenue,
    COUNT(order_id) AS orders_count
  FROM
    order_revenue
  GROUP BY
    date
),
running_revenue AS (
  SELECT
    d.date,
    SUM(COALESCE(dr.revenue, 0)) OVER (
      ORDER BY
        d.date ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_revenue,
    SUM(COALESCE(dr.orders_count, 0)) OVER (
      ORDER BY
        d.date ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_orders_count
  FROM
    dates d
    LEFT JOIN daily_revenue dr ON dr.date = d.date
)
SELECT
  rr.date,
  ROUND(
    rr.running_revenue :: numeric / rnou.running_total_users,
    2
  ) AS running_arpu,
  ROUND(
    rr.running_revenue :: numeric / rnou.running_paying_users,
    2
  ) AS running_arppu,
  ROUND(
    rr.running_revenue :: numeric / rr.running_orders_count,
    2
  ) AS running_aov
FROM
  running_revenue rr
  JOIN running_number_of_users rnou ON rnou.date = rr.date
ORDER BY
  rr.date
