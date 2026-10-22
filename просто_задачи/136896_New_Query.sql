-- Redash query ID: 136896
-- Name: New Query

select Concat('Заказ № ' , order_id,  'создан', creation_time)
from orders
