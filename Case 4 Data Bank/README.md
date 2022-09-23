# Case Study #4 - Data Bank

- [Case Study #4 - Data Bank](#case-study-4---data-bank)
	- [A. Customer Node Exploration](#a-customer-node-exploration)
	- [B. Customer Transactions](#b-customer-transactions)

## A. Customer Node Exploration
1. How many unique nodes are there on the Data Bank system?

```sql
SELECT COUNT(DISTINCT region_id, node_id) as unique_nodes FROM customer_nodes;
```

| unique_nodes      |
| ----------------- |
| 25                |

There are 25 unique nodes across all regions.

2. What is the number of nodes per region?

```sql
SELECT region_name, COUNT(DISTINCT node_id) as nodes_per_region 
FROM customer_nodes as cn
JOIN regions as r
	ON cn.region_id = r.region_id
GROUP BY cn.region_id;
```

| region_name      | nodes_per_region      |
| ---------------- | --------------------- |
| Australia        | 5                     |
| America          | 5                     |
| Africa           | 5                     |
| Asia             | 5                     |
| Europe           | 5                     |

Each region has 5 nodes.

3. How many customers are allocated to each region?

```sql
SELECT region_name, COUNT(DISTINCT customer_id) as customers_per_region 
FROM customer_nodes as cn
JOIN regions as r
	ON cn.region_id = r.region_id
GROUP BY cn.region_id;
```

| region_name      | customers_per_region      |
| ---------------- | ------------------------- |
| Australia        | 110                       |
| America          | 105                       |
| Africa           | 102                       |
| Asia             | 95                        |
| Europe           | 88                        |

Australia has the most customers, while Europe has the least.

4. How many days on average are customers reallocated to a different node?

```sql
SELECT FORMAT(AVG(DATEDIFF(end_date, start_date)),2) as avg_days 
FROM customer_nodes 
WHERE end_date!='9999-12-31';
```

| avg_days      |
| ------------- |
| 14.63         |

Customers reallocated for every average 14 days on average. This exclude the data where `end_date` column has the value 9999-12-31. This value mean that the customer has not been reallocated again to another node. 

5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

```sql
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
```

| days      | percentile      |
| --------- | --------------- |
| 15        | 0.50            |
| 23        | 0.80            |
| 28        | 0.95            |

For this data, the median (15 days) is around the same as the mean (14.6 days). The median mean half of the reallocation intervals is 15 days or below. The 95% percentile means that only 5% of the reallocation intervals is above 28 days. 

## B. Customer Transactions
1. What is the unique count and total amount for each transaction type?

```sql
SELECT 
	txn_type, 
	COUNT(DISTINCT txn_amount) as txn_count_unique_amount, 
	SUM(txn_amount) as txn_total_amount
FROM customer_transactions
GROUP BY txn_type;
```
| txn_type      | txn_count_unique_amount      | txn_total_amount      |
| ------------- | ---------------------------- | --------------------- |
| deposit       | 929                          | 1359168               |
| purchase      | 815                          | 806537                |
| withdrawal    | 804                          | 793003                |

Deposit transaction is the most frequent transaction with the highest amount. On the other hand, the total amount of purhcase and withdrawal transactions is higher than deposit amount.

2. What is the average total historical deposit counts and amounts for all customers?

```sql
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
```

| avg_deposit_count      | avg_total_deposit      |
| ---------------------- | ---------------------- |
| 5.34                   | 2,718                  |

3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql
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
```

| txn_month      | customer_count      |
| -------------- | ------------------- |
| January        | 115                 |
| February       | 108                 |
| March          | 113                 |
| April          | 50                  |

The table above describe the amount of customer that make more than 1 deposit (`deposit_count>1`) and either 1 purchase or 1 withdrawal (`purchase_count=1` or `withdrawal_count=1`) for each month.

4. What is the closing balance for each customer at the end of the month?

```sql
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
```

| customer_id      | month      | balance_change      | closing_balance      |
| ---------------- | ---------- | ------------------- | -------------------- |
| 1                | January    | 312                 | 312                  |
| 1                | February   | 0                   | 312                  |
| 1                | March      | -952                | -640                 |
| 1                | April      | 0                   | -640                 |
| 2                | January    | 549                 | 549                  |
| 2                | February   | 0                   | 549                  |
| 2                | March      | 61                  | 610                  |
| 2                | April      | 0                   | 610                  |
| 3                | January    | 144                 | 144                  |
| 3                | February   | -965                | -821                 |
| 3                | March      | -401                | -1222                |
| 3                | April      | 493                 | -729                 |
| 4                | January    | 848                 | 848                  |
| 4                | February   | 0                   | 848                  |
| 4                | March      | -193                | 655                  |
| 4                | April      | 0                   | 655                  |

The table above is the output for the query (with limit of 4 customer). For this problem, I need to make a new temporary table to add the gap between transaction month. For example, the first customer only has transactions on January and March (Missing February and April). A similar problem where I need to add the missing gap between number also on Case Study #3 Part C.

5. What is the percentage of customers who increase their closing balance by more than 5%?

```sql
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
		FROM 
			(SELECT 
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
```

| percentage      |
| --------------- |
| 40.60%          |

For this problem, I only take into acccount the closing balance on the first month (January) and the last month (April). 40.60% of the customer has increase their closing balance by more than 5%. 