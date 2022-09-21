-- Author: Elbert Timothy Lasiman

#################################

-- A. Customer Nodes Exploration

-- Q1: How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT region_id, node_id) as unique_nodes FROM customer_nodes;

-- Q2: What is the number of nodes per region?
SELECT region_name, COUNT(DISTINCT node_id) as nodes_per_region 
FROM customer_nodes as cn
JOIN regions as r
	ON cn.region_id = r.region_id
GROUP BY cn.region_id;

-- Q3: How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT customer_id) as customers_per_region 
FROM customer_nodes as cn
JOIN regions as r
	ON cn.region_id = r.region_id
GROUP BY cn.region_id;

-- Q4: How many days on average are customers reallocated to a different node?
SELECT FORMAT(AVG(DATEDIFF(end_date, start_date)),2) as avg_days 
FROM customer_nodes 
WHERE end_date!='9999-12-31';

-- Q5: What is the median, 80th and 95th percentile for this same reallocation days metric for each region
SELECT 
	date_diff as days,
    FORMAT(ranking/max_rank, 2) as percentile
FROM (
	SELECT *, 
    DATEDIFF(end_date, start_date) as date_diff, 
    ROW_NUMBER() OVER(ORDER BY DATEDIFF(end_date, start_date)) as ranking
	FROM customer_nodes 
    JOIN (SELECT COUNT(*) as max_rank FROM customer_nodes WHERE end_date!='9999-12-31') as t
	WHERE end_date!='9999-12-31'
    ORDER BY DATEDIFF(end_date, start_date)) as t
WHERE 
	ranking = ROUND((max_rank)*0.5) -- median
	OR ranking = ROUND((max_rank*0.8)) -- 80th percentile
    OR ranking = ROUND((max_rank)*0.95); -- 95th percentile

#################################

-- B. Customer Transactions

-- Q1: What is the unique count and total amount for each transaction type?
SELECT 
	txn_type, 
	COUNT(DISTINCT txn_amount) as txn_count_unique_amount, 
	SUM(txn_amount) as txn_total_amount
FROM customer_transactions
GROUP BY txn_type;

-- Q2: What is the average total historical deposit counts and amounts for all customers?
SELECT
	FORMAT(AVG(deposit_count), 2) as avg_deposit_count,
	FORMAT(AVG(total_deposit), 0) as avg_total_deposit
FROM 
	(SELECT 
		customer_id, 
		COUNT(txn_amount) as deposit_count, 
		SUM(txn_amount) as total_deposit
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id) as t;

-- Q3: For each month - how many Data Bank customers make more than 1 deposit
-- and either 1 purchase or 1 withdrawal in a single month?
SELECT 
	txn_month,
	COUNT(DISTINCT customer_id) as customer_count
FROM 
	(SELECT 
		*,
		MONTH(txn_date) as txn_month_n,
		MONTHNAME(txn_date) as txn_month,
		SUM(txn_type='deposit') as deposit_count,
		SUM(txn_type='purchase') as purchase_count,
		SUM(txn_type='withdrawal') as withdrawal_count
	FROM customer_transactions
	GROUP BY customer_id, MONTH(txn_date)
	ORDER BY customer_id
) as t
WHERE 
	deposit_count>1
    AND (purchase_count=1 OR withdrawal_count=1)
GROUP BY txn_month
ORDER BY txn_month_n;

-- Q4: What is the closing balance for each customer at the end of the month?
-- (I'll limit the month only from Jan 2020 - Apr 2020 as these are the only months the table have)
-- creating temporary number table to add the missing month gap
DROP TABLE IF EXISTS num_temp;
CREATE TABLE num_temp 
	SELECT 
		ROW_NUMBER() OVER W as n
    FROM customer_transactions 
    WINDOW W AS (ORDER BY customer_id) LIMIT 4;
SELECT * FROM num_temp;

SELECT customer_id, month, balance_change,
    (CASE WHEN month = 'January'
		THEN @balance := balance_change
        ELSE @balance := @balance + balance_change
	END) as closing_balance
FROM 
	(SELECT 
		customer_id,
		MONTHNAME(STR_TO_DATE(n,'%m')) as month,
		SUM(CASE 
				WHEN n != MONTH(txn_date) THEN 0
				WHEN txn_type='deposit' THEN txn_amount ELSE -txn_amount END) as balance_change
	FROM customer_transactions
	LEFT JOIN num_temp as n
		ON n
	GROUP BY customer_id, n
	ORDER BY customer_id
) as t,
(SELECT @balance := 0, @cus_id := 0) as var;

-- Q5: What is the percentage of customers who increase their closing balance by more than 5%?
SELECT 
	CONCAT(FORMAT(COUNT(DISTINCT customer_id)/total_customer*100, 2),'%') as percentage
FROM
	(SELECT 
		*,
        LAG(closing_balance) OVER (PARTITION BY customer_id) as 'january_closing_balance'
	FROM
		(SELECT 
			customer_id, month, balance_change,
			(CASE WHEN month = 'January'
				THEN @balance := balance_change
				ELSE @balance := @balance + balance_change
			END) as closing_balance
		FROM (
			SELECT 
				customer_id,
				MONTHNAME(STR_TO_DATE(n,'%m')) as month,
				FORMAT(SUM(CASE 
						WHEN n != MONTH(txn_date) THEN 0
						WHEN txn_type='deposit' THEN txn_amount ELSE -txn_amount END), 0) as balance_change
			FROM customer_transactions
			LEFT JOIN num_temp as n
				ON n
			GROUP BY customer_id, n
			ORDER BY customer_id) as t,
			(SELECT @balance := 0, @cus_id := 0) as var) as t
	WHERE 
		month = 'January' 
		OR month = 'April') as t,
	(SELECT COUNT(DISTINCT customer_id) as total_customer from customer_transactions) as total
WHERE (closing_balance-january_closing_balance)/ABS(january_closing_balance)*100 > 5;

#################################