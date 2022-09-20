-- Author: Elbert Timothy Lasiman

-- ------------------------------

# A. Customer Journey

SELECT customer_id, s.plan_id, p.plan_name, start_date 
FROM subscriptions as s 
JOIN plans as p ON s.plan_id = p.plan_id WHERE customer_id<=8;

-- ------------------------------

-- B. Data Analysis Question

-- Q1: How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) as customers FROM subscriptions;

-- Q2: What is the monthly distribution of trial plan start_date values for our dataset - 
-- use the start of the month as the group by value
SELECT MONTHNAME(start_date) as month, COUNT(plan_id) as num_trial
FROM subscriptions
WHERE plan_id = 0
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);

-- Q3: What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name
SELECT p.plan_name, COUNT(s.plan_id) as num_plan
FROM subscriptions as s
JOIN plans as p
	ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date)>2020
GROUP BY p.plan_name
ORDER BY p.plan_id;

-- Q4: What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
	SUM(plan_id=4) as num_churned, 
	CONCAT_WS('', FORMAT(SUM(plan_id=4)/COUNT(DISTINCT customer_id)*100, 1), '%') as churned_percentage 
FROM subscriptions;

-- Q5: How many customers have churned straight after their initial free trial -
-- what percentage is this rounded to the nearest whole number?
SELECT 
	COUNT(customer_id) as count_churned, 
    CONCAT_WS('', FORMAT(COUNT(customer_id)/total_customer*100, 0), '%') as churned_percentage
FROM (
	SELECT 
		s.customer_id, 
		s.plan_id as trial, 
        c.plan_id as churn, 
        s.start_date as trial_start, 
        c.start_date as churn_start, 
        DATEDIFF(c.start_date, s.start_date) as day_diff
	FROM subscriptions as s
	LEFT JOIN subscriptions as c
		ON s.customer_id = c.customer_id AND c.plan_id=4
	WHERE s.plan_id=0 AND DATEDIFF(c.start_date, s.start_date)<=7
) AS tmp
JOIN (SELECT COUNT(DISTINCT customer_id) as total_customer FROM subscriptions) as t;

-- Q6: What is the number and percentage of customer plans after their initial free trial?
SELECT 
	next_plan_name, 
	COUNT(next_plan_name) as num_plan,
	CONCAT_WS('', FORMAT(COUNT(next_plan_name)/total_customer*100, 0), '%') as percentage
FROM (
	SELECT 
		s.customer_id, p.plan_name, s.start_date, 
		LEAD(p.plan_name) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_name
	FROM subscriptions as s
	JOIN plans as p
		ON s.plan_id = p.plan_id
) AS tmp
JOIN (SELECT COUNT(DISTINCT customer_id) as total_customer FROM subscriptions) as t
WHERE plan_name='trial'
GROUP BY next_plan_name;

-- Q7: What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT 
	plan_name, 
    COUNT(plan_name) as num_plan,
    CONCAT_WS('', FORMAT(COUNT(plan_name)/total_customer*100, 1), '%') as plan_percentage
FROM
	(SELECT 
		s.customer_id,
        s.plan_id,
		p.plan_name,
		s.start_date,
		LEAD(start_date) OVER(PARTITION BY s.customer_id ORDER BY start_date) as next_start_date
	FROM subscriptions as s
	JOIN plans as p
		ON s.plan_id=p.plan_id) as t
JOIN (SELECT COUNT(DISTINCT customer_id) as total_customer FROM subscriptions) as total
WHERE start_date <='2020-12-31' 
	AND (next_start_date IS NULL OR next_start_date>'2020-12-31')
GROUP BY plan_name
ORDER BY plan_id;

-- Q8: How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(customer_id) as num_plan_annual
FROM subscriptions
WHERE plan_id=3 AND YEAR(start_date) = 2020;

-- Q9: How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT (DATEDIFF(start_annual, start_trial)) as average_day
FROM 
	(
	SELECT
		start_date as start_trial,
		LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date) as start_annual
	FROM subscriptions 
	WHERE plan_id=0 OR plan_id=3
	) as t
WHERE start_annual IS NOT NULL;

-- Q10: Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT CONCAT_WS(' - ', day_range_start, day_range_end) as day_range, num_annual
FROM (
	SELECT 
	  FLOOR(average_day/30) * 30 + 1 as day_range_start,
	  FLOOR(average_day/30) * 30 + 30 as day_range_end,
	  COUNT(*) AS num_annual
	FROM (
		SELECT (DATEDIFF(start_annual, start_trial)) as average_day
		FROM 
			(
			SELECT
				start_date as start_trial,
				LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date) as start_annual
			FROM subscriptions 
			WHERE plan_id=0 OR plan_id=3
			) as t
		WHERE start_annual IS NOT NULL) as t
	GROUP BY day_range_start
	ORDER BY day_range_end) as t;

-- Q11: How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT 
	COUNT(*) as count_downgrade
FROM (SELECT *,
		LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) as next_plan_id
	FROM subscriptions) as t
WHERE plan_id = 2 AND next_plan_id = 1;

-- ------------------------------

-- C. Challenge Payment Question
DROP TABLE IF EXISTS num_temp;
CREATE TABLE num_temp
	SELECT ROW_NUMBER() OVER W as n FROM subscriptions WINDOW W AS (ORDER BY customer_id) LIMIT 13;
SELECT * FROM num_temp;

DROP TABLE IF EXISTS payments;
CREATE TABLE payments
SELECT 
	customer_id, plan_id, plan_name, 
	(CASE 
		WHEN plan_name LIKE '%monthly' THEN ADDDATE(start_date, INTERVAL n-1 MONTH)
        WHEN plan_name LIKE '%annual' THEN ADDDATE(start_date, INTERVAL n-1 YEAR)
	END) as payment_date,
    amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY 
		(CASE 
			WHEN plan_name LIKE '%monthly' THEN ADDDATE(start_date, INTERVAL n-1 MONTH)
			WHEN plan_name LIKE '%annual' THEN ADDDATE(start_date, INTERVAL n-1 YEAR)
		END)) as payment_order 
FROM
(
	SELECT *
	FROM
	(
		SELECT *,
			(CASE 
				WHEN plan_name LIKE '%monthly' AND next_plan_name IS NOT NULL 
				THEN CASE
					WHEN DAY(next_start_date) <= DAY(start_date)
					THEN MONTH(next_start_date) - MONTH(start_date)
					ELSE MONTH(next_start_date) - MONTH(start_date) + 1 END
				WHEN plan_name LIKE '%monthly' AND next_plan_name IS NULL 
				THEN CASE
					WHEN DAY(start_date) >= 31
					THEN 12 - MONTH(start_date)
					ELSE 12 - MONTH(start_date) + 1 END
				WHEN plan_name LIKE '%annual' THEN 1
			END) as num_of_billing
		FROM(
		SELECT 
			s.customer_id, 
			s.plan_id, 
			p.plan_name,
			s.start_date,
			p.price as amount,
			LEAD(plan_Name) OVER(PARTITION BY customer_id ORDER BY start_date) as next_plan_name,
			LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date) as next_start_date
		FROM 
			subscriptions as s
		JOIN plans as p
			ON s.plan_id = p.plan_id
		WHERE s.plan_id!=0 AND YEAR(start_date)=2020
		) as t
	) as t
	LEFT JOIN num_temp as n
		ON n <= num_of_billing
	ORDER BY customer_id, start_date
) as t
WHERE plan_id!=4;

SELECT * FROM payments WHERE customer_id<=10;

-- ------------------------------

-- D. Outside The Box Questions
SELECT 
	*,
    MONTH(p.payment_date),
    MONTH(n.next_payment_date)
FROM payments as p
JOIN (SELECT
		customer_id, payment_date,
		LEAD(payment_date) OVER(PARTITION BY customer_id ORDER BY payment_date) as next_payment_date,
		LEAD(amount) OVER(PARTITION BY customer_id ORDER BY payment_date) as next_amount
	FROM payments
	ORDER BY customer_id, MONTH(payment_date)) as n
    ON p.customer_id = n.customer_id AND p.payment_date = n.payment_date
    
;

SELECT 
	*,
    CONCAT(FORMAT((revenue-(LAG(revenue) OVER W))/(LAG(revenue) OVER W) * 100, 0), '%') as growth
FROM (SELECT
		MONTH(payment_date) as month, SUM(amount) as revenue 
	FROM payments
	GROUP BY MONTH(payment_date)
    ORDER BY MONTH(payment_date)) as t
WINDOW W AS (ORDER BY month);