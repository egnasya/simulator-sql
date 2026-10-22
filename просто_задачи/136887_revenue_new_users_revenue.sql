-- Redash query ID: 136887
-- Name: revenue, new_users_revenue

WITH cancel_order as (
    SELECT order_id
    FROM user_actions
    WHERE action = 'cancel_order'),
    
first_user_date as (
    SELECT user_id, MIN(time::DATE) as first_date
    FROM user_actions ua
    GROUP BY user_id),

order_costs  as (
    SELECT order_id, creation_time::DATE as date, SUM(price) order_cost
    FROM orders o
    CROSS JOIN LATERAL UNNEST(product_ids) as t(product_id)
    LEFT JOIN products p USING(product_id)
    WHERE NOT EXISTS(SELECT 1 FROM cancel_order ca WHERE ca.order_id = o.order_id)
    GROUP BY order_id, date),
    
user_revenue_per_day as (
    SELECT time::DATE as action_date, user_id, SUM(order_cost) user_daily_revenue
    FROM user_actions
    LEFT JOIN order_costs oc USING(order_id)
    WHERE action = 'create_order'
    GROUP BY action_date, user_id),
    
new_users_revenue_per_day as ( 
    SELECT action_date as date, SUM(user_daily_revenue) as new_users_revenue
    FROM user_revenue_per_day ur
    LEFT JOIN first_user_date fu USING(user_id)
    WHERE ur.action_date = fu.first_date
    GROUP BY date
    ORDER By date),
    
revenue_per_day as(    
    SELECT action_date as date, SUM(user_daily_revenue) as revenue
    FROM user_revenue_per_day
    GROUP BY date
    ORDER BY action_date)
    
SELECT date,
revenue,
new_users_revenue,
ROUND(100*(new_users_revenue::decimal/revenue),2) as new_users_revenue_share,
ROUND(100*((revenue - new_users_revenue)::decimal/revenue),2) as old_users_revenue_share
FROM revenue_per_day
LEFT JOIN new_users_revenue_per_day using(date)
ORDER BY date
