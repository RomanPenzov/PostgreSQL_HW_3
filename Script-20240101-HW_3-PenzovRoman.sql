-- -- ранее в HW_2 уже были созданы таблицы customer_20240101 и transaction_20240101

-- Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества

SELECT job_industry_category, COUNT(*) AS count
FROM customer_20240101
GROUP BY job_industry_category
ORDER BY count DESC;

-- Найти сумму транзакций за каждый месяц по сферам деятельности, отсортировав по месяцам и по сфере деятельности

SELECT 
    EXTRACT(MONTH FROM TO_DATE(t.transaction_date, 'DD-MM-YYYY')) AS transaction_month,
    c.job_industry_category,
    SUM(t.list_price) AS total_transaction_amount
FROM 
    customer_20240101 c
JOIN 
    transaction_20240101 t ON c.customer_id = t.customer_id
GROUP BY 
    transaction_month, c.job_industry_category
ORDER BY 
    transaction_month ASC, c.job_industry_category ASC;
   
-- Найти по всем клиентам сумму всех транзакций (list_price), максимум, минимум и количество транзакций, 
-- отсортировав результат по убыванию суммы транзакций и количества транзакций. 
-- Выполните двумя способами: используя только group by и используя только оконные функции. Сравните результат.

-- с помощью GROUP BY
SELECT
    c.customer_id,
    SUM(t.list_price) AS total_transaction_amount,
    MAX(t.list_price) AS max_transaction_amount,
    MIN(t.list_price) AS min_transaction_amount,
    COUNT(t.transaction_id) AS transaction_count
FROM
    customer_20240101 c
JOIN
    transaction_20240101 t ON c.customer_id = t.customer_id
GROUP BY
    c.customer_id
ORDER BY
    total_transaction_amount DESC, transaction_count DESC;
   
-- используя только оконные функции   
SELECT DISTINCT
    c.customer_id,
    SUM(t.list_price) OVER (PARTITION BY c.customer_id) AS total_transaction_amount,
    MAX(t.list_price) OVER (PARTITION BY c.customer_id) AS max_transaction_amount,
    MIN(t.list_price) OVER (PARTITION BY c.customer_id) AS min_transaction_amount,
    COUNT(t.transaction_id) OVER (PARTITION BY c.customer_id) AS transaction_count
FROM
    customer_20240101 c
JOIN
    transaction_20240101 t ON c.customer_id = t.customer_id
ORDER BY
    total_transaction_amount DESC, transaction_count DESC;
   
-- Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций за весь период (сумма транзакций не может быть null).
-- Напишите отдельные запросы для минимальной и максимальной суммы.

-- для минимальной суммы транзакций
WITH Transaction_Summary AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(t.list_price) AS total_transaction_amount
    FROM
        customer_20240101 c
    JOIN
        transaction_20240101 t ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
    HAVING
        SUM(t.list_price) IS NOT NULL
)
SELECT
    first_name,
    last_name,
    total_transaction_amount
FROM
    Transaction_Summary
WHERE
    total_transaction_amount = (SELECT MIN(total_transaction_amount) FROM Transaction_Summary);
   
-- для максимальной суммы  
WITH Transaction_Summary AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(t.list_price) AS total_transaction_amount
    FROM
        customer_20240101 c
    JOIN
        transaction_20240101 t ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
    HAVING
        SUM(t.list_price) IS NOT NULL
)
SELECT
    first_name,
    last_name,
    total_transaction_amount
FROM
    Transaction_Summary
WHERE
    total_transaction_amount = (SELECT MAX(total_transaction_amount) FROM Transaction_Summary);
   
-- Вывести только самые первые транзакции клиентов. Решить с помощью оконных функций

SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY TO_DATE(transaction_date, 'DD-MM-YYYY')) AS row_num
    FROM
        transaction_20240101
) AS ranked_transactions
WHERE
    row_num = 1;

-- Вывести имена, фамилии и профессии клиентов, между транзакциями которых был максимальный интервал (интервал вычисляется в днях)
   
WITH Transaction_Intervals AS (
    SELECT
        customer_id,
        transaction_date,
        LAG(transaction_date) OVER (PARTITION BY customer_id ORDER BY TO_DATE(transaction_date, 'DD-MM-YYYY')) AS previous_transaction_date,
        TO_DATE(transaction_date, 'DD-MM-YYYY') - TO_DATE(LAG(transaction_date) OVER (PARTITION BY customer_id ORDER BY TO_DATE(transaction_date, 'DD-MM-YYYY')), 'DD-MM-YYYY') AS interval
    FROM
        transaction_20240101
)
SELECT
    c.first_name,
    c.last_name,
    c.job_title
FROM
    Transaction_Intervals ti
JOIN
    customer_20240101 c ON ti.customer_id = c.customer_id
WHERE
    ti.interval = (SELECT MAX(interval) FROM Transaction_Intervals);





   
