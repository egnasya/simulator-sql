-- Redash query ID: 137871
-- Name: дневной_retention_по_когортам_пользователей

-- На основе данных в таблице user_actions рассчитайте показатель дневного Retention для всех пользователей, разбив их на когорты по дате первого взаимодействия с нашим приложением.
-- В результат включите четыре колонки: месяц первого взаимодействия, дату первого взаимодействия, количество дней, прошедших с даты первого взаимодействия (порядковый номер 
-- дня начиная с 0), и само значение Retention. Метрику необходимо выразить в виде доли, округлив полученные значения до двух знаков после запятой. Месяц первого взаимодействия 
-- укажите в виде даты, округлённой до первого числа месяца. Результат должен быть отсортирован сначала по возрастанию даты первого взаимодействия, затем по возрастанию 
-- порядкового номера дня.
-- Поля в результирующей таблице: start_month, start_date, day_number, retention

SELECT
    start_month,
    start_date,
    day_number,
    ROUND(COUNT(DISTINCT user_id) * 1.0 / MAX(COUNT(DISTINCT user_id)) OVER(PARTITION BY start_date), 2) AS retention
FROM (
    SELECT
        user_id,
        DATE_TRUNC('month', MIN(time::date) OVER(PARTITION BY user_id))::date AS start_month,
        MIN(time::date) OVER(PARTITION BY user_id) AS start_date,
        (time::date - MIN(time::date) OVER(PARTITION BY user_id)) AS day_number
    FROM user_actions
) t
GROUP BY 
    start_month,
    start_date,
    day_number
ORDER BY start_date, day_number
