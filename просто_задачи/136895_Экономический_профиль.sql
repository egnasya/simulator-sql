-- Redash query ID: 136895
-- Name: Экономический профиль

with 
t1 as (
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
order by 1), 

t2 as (    
select date, sum(price) as revenue, sum(tax) as tax
from (
    select date, product_id, name, price,
    case
    when name in ('сахар', 'сухарики', 'сушки', 'семечки', 
    'масло льняное', 'виноград', 'масло оливковое', 
    'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
    'овсянка', 'макароны', 'баранина', 'апельсины', 
    'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
    'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
    'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
    'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
    'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') then round(price * 10/110, 2)
    else round(price * 20/120, 2) end as tax
    from (
        select creation_time::date as date, unnest(product_ids) as product_id
        from orders
        where order_id not in (select order_id from user_actions where action = 'cancel_order')) l
        left join products using (product_id)) i      
group by 1
order by 1)

select date, revenue, costs, round(tax, 2) as tax, round(revenue - costs - tax, 2) as gross_profit,
sum(revenue) over(order by date) as total_revenue, 
sum(costs) over (order by date) as total_costs, 
sum(tax) over (order by date) as total_tax, 
sum(revenue - costs - tax) over (order by date) as total_gross_profit,
round((revenue - costs - tax) / revenue * 100, 2) as gross_profit_ratio,
round((sum(revenue - costs - tax) over (order by date)) / (sum(revenue) over(order by date)) * 100, 2) as total_gross_profit_ratio
from t1   
    left join t2 using (date)
