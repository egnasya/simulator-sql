-- Redash query ID: 136886
-- Name: New Query

select * from (select * from users limit 100) as q order by user_id
