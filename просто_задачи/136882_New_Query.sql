-- Redash query ID: 136882
-- Name: New Query

select order_id, name from 

(select order_id,unnest(product_ids) product_id from orders) t1 join products using(product_id))
where order_id not in (select order_id from user_actions where action='cancel_order')
order by order_id
