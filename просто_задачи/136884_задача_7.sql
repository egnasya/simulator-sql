-- Redash query ID: 136884
-- Name: задача 7

select date, sum(price) as revenue
from (
    select creation_time::date as date, unnest(product_ids) as product_id
    from orders
    where order_id not in (select order_id from user_actions where action = 'cancel_order')) t1
    left join products using (product_id)
group by 1
order by 1


select date, fc + orders_create * sborka + zakaz * orders_deliv + bonus * couriers_bonus as costs
from (
    select date, orders_create,
    case
    when date_part('month', date) = 8 then 120000
    when date_part('month', date) = 9 then 150000
    end as FC,
    case
    when date_part('month', date) = 8 then 140
    when date_part('month', date) = 9 then 115
    end as sborka,
    150 as zakaz,
    case
    when date_part('month', date) = 8 then 400
    when date_part('month', date) = 9 then 500
    end as bonus,
    coalesce(couriers_bonus, 0) as couriers_bonus,
    orders_deliv
    from (
        select creation_time::date as date, count(order_id) as orders_create
        from orders
        where order_id not in (select order_id from user_actions where action = 'cancel_order')
        group by 1) a
        left join (
            select date, count(courier_id) as couriers_bonus
            from (
                select time::date as date, courier_id, count(order_id)
                from courier_actions
                where action = 'deliver_order'
                group by 1, 2
                having count(order_id) >= 5) c
            group by 1) d using (date)
        left join (
        select time::date as date, count(order_id) as orders_deliv
        from courier_actions
        where action = 'deliver_order'
        group by 1) f using (date)) k
order by 1
