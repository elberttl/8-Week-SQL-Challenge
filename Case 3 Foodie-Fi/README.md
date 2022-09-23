# Case Study #3 - Foodie-Fi

- [Case Study #3 - Foodie-Fi](#case-study-3---foodie-fi)
	- [A. Customer Journey](#a-customer-journey)
	- [B. Data Analysis Questions](#b-data-analysis-questions)
	- [C. Challenge Payment Order](#c-challenge-payment-order)
	- [D. Outside The Box Questions](#d-outside-the-box-questions)

## A. Customer Journey

Here are 8 sample customers based on the data.

``` sql 
SELECT customer_id, s.plan_id, p.plan_name, start_date 
FROM subscriptions as s 
JOIN plans as p ON s.plan_id = p.plan_id WHERE customer_id<=8;
```

| customer_id      | plan_id      | plan_name      | start_date      |
| ---------------- | ------------ | -------------- | --------------- |
| 1                | 0            | trial          | 2020-08-01      |
| 1                | 1            | basic monthly  | 2020-08-08      |
| 2                | 0            | trial          | 2020-09-20      |
| 2                | 3            | pro annual     | 2020-09-27      |
| 3                | 0            | trial          | 2020-01-13      |
| 3                | 1            | basic monthly  | 2020-01-20      |
| 4                | 0            | trial          | 2020-01-17      |
| 4                | 1            | basic monthly  | 2020-01-24      |
| 4                | 4            | churn          | 2020-04-21      |
| 5                | 0            | trial          | 2020-08-03      |
| 5                | 1            | basic monthly  | 2020-08-10      |
| 6                | 0            | trial          | 2020-12-23      |
| 6                | 1            | basic monthly  | 2020-12-30      |
| 6                | 4            | churn          | 2021-02-26      |
| 7                | 0            | trial          | 2020-02-05      |
| 7                | 1            | basic monthly  | 2020-02-12      |
| 7                | 2            | pro monthly    | 2020-05-22      |
| 8                | 0            | trial          | 2020-06-11      |
| 8                | 1            | basic monthly  | 2020-06-18      |
| 8                | 2            | pro monthly    | 2020-08-03      |

Brief description about each customer:
1. Customer #1: Start with trial first, then upgrade to basic monthly after the trial has ended.
2. Customer #2: Start with trial, then upgrade to pro annual after trial has ended.
3. Customer #3: Start with trial, then upgrade to basic monthly after trial has ended.
4. Customer #4: Start with trial, then upgrade to basic monthly after trial has ended, and cancel their plan after 3 months of subscribing.
5. Customer #5: Start with trial, then upgrade to basic monthly after trial has ended.
6. Customer #6: Start with trial, then upgrade to basic monthly after trial has ended, and cancel their plan after 2 months of subscribing.
7. Customer #7: Start with trial, then upgrade to basic monthly after trial has ended, and upgrade again to pro monthly at the 4th month of subscribing.
8. Customer #8: Start with trial, then upgrade to basic monthly after trial has ended, and upgrade again to pro monthly at the 2nd month of subscribing.

## B. Data Analysis Questions

1. How many customers has Foodie-Fi ever had?

``` sql
SELECT COUNT(DISTINCT customer_id) as customers FROM subscriptions;
```

| customers      |
| -------------- |
| 1000           |

There are 1000 customers Foodie-Fi ever had.

2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

``` sql
SELECT MONTHNAME(start_date) as month, COUNT(plan_id) as num_trial
FROM subscriptions
WHERE plan_id = 0
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date);
```

| month      | num_trial      |
| ---------- | -------------- |
| January    | 88             |
| February   | 68             |
| March      | 94             |
| April      | 81             |
| May        | 88             |
| June       | 79             |
| July       | 89             |
| August     | 88             |
| September  | 87             |
| October    | 79             |
| November   | 75             |
| December   | 84             |

The table shows the trial subscription distribution for each month. The highest number of trial plan is in March. 

3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each 

``` sql
SELECT p.plan_name, COUNT(s.plan_id) as num_plan
FROM subscriptions as s
JOIN plans as p
	ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date)>2020
GROUP BY p.plan_name
ORDER BY p.plan_id;
```

| plan_name      | num_plan      |
| -------------- | ------------- |
| basic monthly  | 8             |
| pro monthly    | 60            |
| pro annual     | 63            |
| churn          | 71            |

After year 2020, there is no new trial subscription and only a few basic plan subscription. Most of the customers subscribe to pro plan, with the number of monthly and annual plan roughly the same. There are also a large number of customers who cancel their plan. 

4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

``` sql
SELECT 
	SUM(plan_id=4) as num_churned, 
	CONCAT_WS('', FORMAT(SUM(plan_id=4)/COUNT(DISTINCT customer_id)*100, 1), '%') as churned_percentage 
FROM subscriptions;
```

| num_churned      | churned_percentage      |
| ---------------- | ----------------------- |
| 307              | 30.7%                   |

About one third of the customer cancel their plan.

5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
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
```

| count_churned      | churned_percentage      |
| ------------------ | ----------------------- |
| 92                 | 9%                      |

There are 92 customers or 9% of all customers who churned after their trial ended. Here is the output of the tmp subquery (limit to 5 rows)

| customer_id      | trial      | churn      | trial_start      | churn_start      | day_diff      |
| ---------------- | ---------- | ---------- | ---------------- | ---------------- | ------------- |
| 11               | 0          | 4          | 2020-11-19       | 2020-11-26       | 7             |
| 99               | 0          | 4          | 2020-12-05       | 2020-12-12       | 7             |
| 108              | 0          | 4          | 2020-09-10       | 2020-09-17       | 7             |
| 122              | 0          | 4          | 2020-03-30       | 2020-04-06       | 7             |
| 128              | 0          | 4          | 2020-01-19       | 2020-01-26       | 7             |

6. What is the number and percentage of customer plans after their initial free trial?

```sql
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
```

| next_plan_name      | num_plan      | percentage      |
| ------------------- | ------------- | --------------- |
| basic monthly       | 546           | 55%             |
| pro annual          | 37            | 4%              |
| pro monthly         | 325           | 33%             |
| churn               | 92            | 9%              |

After trial ended, 88% of the customers choose the monthly plan.

7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

``` sql
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
```

| plan_name      | num_plan      | plan_percentage      |
| -------------- | ------------- | -------------------- |
| trial          | 19            | 1.9%                 |
| basic monthly  | 224           | 22.4%                |
| pro monthly    | 326           | 32.6%                |
| pro annual     | 195           | 19.5%                |
| churn          | 236           | 23.6%                |

Around half of the customers prefer monthly plan and pro plan. 23.6% customer cancelled their plan before 2021.

8. How many customers have upgraded to an annual plan in 2020?

```sql
SELECT COUNT(customer_id) as num_plan_annual
FROM subscriptions
WHERE plan_id=3 AND YEAR(start_date) = 2020;
```

| num_plan_annual      |
| -------------------- |
| 195                  |

195 customers upgraded their plan to annual plan in 2020.

9.  How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql
SELECT FORMAT(AVG(DATEDIFF(start_annual, start_trial)), 0) as average_day
FROM 
	(
	SELECT
		start_date as start_trial,
		LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date) as start_annual
	FROM subscriptions 
	WHERE plan_id=0 OR plan_id=3
	) as t
WHERE start_annual IS NOT NULL;
```

| average_day      |
| ---------------- |
| 105              |

Customer upgrade to annual plan after 105 days from the first trial day on average.

10.  Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

```sql
SELECT CONCAT_WS(' - ', day_range_start, day_range_end) as day_range, num_annual
FROM (
	SELECT 
	  FLOOR(average_day/30) * 30 | 1 as day_range_start,
	  FLOOR(average_day/30) * 30 | 30 as day_range_end,
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
```

| day_range      | num_annual      |
| -------------- | --------------- |
| 1 - 30         | 48              |
| 31 - 60        | 25              |
| 61 - 90        | 33              |
| 91 - 120       | 35              |
| 121 - 150      | 43              |
| 151 - 180      | 35              |
| 181 - 210      | 27              |
| 211 - 240      | 4               |
| 241 - 270      | 5               |
| 271 - 300      | 1               |
| 301 - 330      | 1               |
| 331 - 360      | 1               |

Customers upgraded to annual plan mostly in the first month of subscription, or in the 5th month.


11.  How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
SELECT 
	COUNT(*) as count_downgrade
FROM (SELECT *,
		LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) as next_plan_id
	FROM subscriptions) as t
WHERE plan_id = 2 AND next_plan_id = 1;
```

| count_downgrade      |
| -------------------- |
| 0                    |

There is no customer that downgrade their plan.

## C. Challenge Payment Order

```sql
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

```

Example output (first 10 customers):

| customer_id      | plan_id      | plan_name      | payment_date      | amount      | payment_order      |
| ---------------- | ------------ | -------------- | ----------------- | ----------- | ------------------ |
| 1                | 1            | basic monthly  | 2020-08-08        | 9.90        | 1                  |
| 1                | 1            | basic monthly  | 2020-09-08        | 9.90        | 2                  |
| 1                | 1            | basic monthly  | 2020-10-08        | 9.90        | 3                  |
| 1                | 1            | basic monthly  | 2020-11-08        | 9.90        | 4                  |
| 1                | 1            | basic monthly  | 2020-12-08        | 9.90        | 5                  |
| 2                | 3            | pro annual     | 2020-09-27        | 199.00      | 1                  |
| 3                | 1            | basic monthly  | 2020-01-20        | 9.90        | 1                  |
| 3                | 1            | basic monthly  | 2020-02-20        | 9.90        | 2                  |
| 3                | 1            | basic monthly  | 2020-03-20        | 9.90        | 3                  |
| 3                | 1            | basic monthly  | 2020-04-20        | 9.90        | 4                  |
| 3                | 1            | basic monthly  | 2020-05-20        | 9.90        | 5                  |
| 3                | 1            | basic monthly  | 2020-06-20        | 9.90        | 6                  |
| 3                | 1            | basic monthly  | 2020-07-20        | 9.90        | 7                  |
| 3                | 1            | basic monthly  | 2020-08-20        | 9.90        | 8                  |
| 3                | 1            | basic monthly  | 2020-09-20        | 9.90        | 9                  |
| 3                | 1            | basic monthly  | 2020-10-20        | 9.90        | 10                 |
| 3                | 1            | basic monthly  | 2020-11-20        | 9.90        | 11                 |
| 3                | 1            | basic monthly  | 2020-12-20        | 9.90        | 12                 |
| 4                | 1            | basic monthly  | 2020-01-24        | 9.90        | 1                  |
| 4                | 1            | basic monthly  | 2020-02-24        | 9.90        | 2                  |
| 4                | 1            | basic monthly  | 2020-03-24        | 9.90        | 3                  |
| 5                | 1            | basic monthly  | 2020-08-10        | 9.90        | 1                  |
| 5                | 1            | basic monthly  | 2020-09-10        | 9.90        | 2                  |
| 5                | 1            | basic monthly  | 2020-10-10        | 9.90        | 3                  |
| 5                | 1            | basic monthly  | 2020-11-10        | 9.90        | 4                  |
| 5                | 1            | basic monthly  | 2020-12-10        | 9.90        | 5                  |
| 6                | 1            | basic monthly  | 2020-12-30        | 9.90        | 1                  |
| 7                | 1            | basic monthly  | 2020-02-12        | 9.90        | 1                  |
| 7                | 1            | basic monthly  | 2020-03-12        | 9.90        | 2                  |
| 7                | 1            | basic monthly  | 2020-04-12        | 9.90        | 3                  |
| 7                | 1            | basic monthly  | 2020-05-12        | 9.90        | 4                  |
| 7                | 2            | pro monthly    | 2020-05-22        | 19.90       | 5                  |
| 7                | 2            | pro monthly    | 2020-06-22        | 19.90       | 6                  |
| 7                | 2            | pro monthly    | 2020-07-22        | 19.90       | 7                  |
| 7                | 2            | pro monthly    | 2020-08-22        | 19.90       | 8                  |
| 7                | 2            | pro monthly    | 2020-09-22        | 19.90       | 9                  |
| 7                | 2            | pro monthly    | 2020-10-22        | 19.90       | 10                 |
| 7                | 2            | pro monthly    | 2020-11-22        | 19.90       | 11                 |
| 7                | 2            | pro monthly    | 2020-12-22        | 19.90       | 12                 |
| 8                | 1            | basic monthly  | 2020-06-18        | 9.90        | 1                  |
| 8                | 1            | basic monthly  | 2020-07-18        | 9.90        | 2                  |
| 8                | 2            | pro monthly    | 2020-08-03        | 19.90       | 3                  |
| 8                | 2            | pro monthly    | 2020-09-03        | 19.90       | 4                  |
| 8                | 2            | pro monthly    | 2020-10-03        | 19.90       | 5                  |
| 8                | 2            | pro monthly    | 2020-11-03        | 19.90       | 6                  |
| 8                | 2            | pro monthly    | 2020-12-03        | 19.90       | 7                  |
| 9                | 3            | pro annual     | 2020-12-14        | 199.00      | 1                  |
| 10               | 2            | pro monthly    | 2020-09-26        | 19.90       | 1                  |
| 10               | 2            | pro monthly    | 2020-10-26        | 19.90       | 2                  |
| 10               | 2            | pro monthly    | 2020-11-26        | 19.90       | 3                  |
| 10               | 2            | pro monthly    | 2020-12-26        | 19.90       | 4                  |

## D. Outside The Box Questions

1. How would you calculate the rate of growth for Foodie-Fi?

An overly simplistic approach is to calculate the revenue (or the number of customers) over a time period, such as one month. Here is the formula

$$
Growth = \frac{{revenue_{month_2}-revenue_{month_1}}}{{revenue_{month_1}}}
$$

Now, we can use the newly created table from section C to calculate the growth per month in 2020.

```sql 
SELECT 
	*,
    CONCAT(FORMAT((revenue-(LAG(revenue) OVER W))/(LAG(revenue) OVER W) * 100, 0), '%') as growth
FROM (SELECT
		MONTH(payment_date) as month, SUM(amount) as revenue 
	FROM payments
	GROUP BY MONTH(payment_date)
    ORDER BY MONTH(payment_date)) as t
WINDOW W AS (ORDER BY month);
```

| month      | revenue      | growth      |
| ---------- | ------------ | ----------- |
| 1          | 1282.00      |             |
| 2          | 2772.70      | 116%        |
| 3          | 4203.40      | 52%         |
| 4          | 5804.00      | 38%         |
| 5          | 7026.40      | 21%         |
| 6          | 8378.30      | 19%         |
| 7          | 9860.30      | 18%         |
| 8          | 11610.50     | 18%         |
| 9          | 12486.20     | 8%          |
| 10         | 14416.40     | 15%         |
| 11         | 12306.50     | -15%        |
| 12         | 12774.00     | 4%          |

From the table, we can see that the company growth is fast at first, and gradually slowing. The growth is also almost always positive, with October-November growth as an exception. 

2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

One key metric I recommend is the revenue. Revenue can indicate how successful Foodie-Fi is. Others key metric are the customers and the site traffic. 

3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

As a food video provider, I think how customers perceive and interact with the website need to be analyzed. How long customers watch video can also be analyzed. This way, we can know if our service is satisfying or not.

4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions woul you include in the survey?

Two simple questions including: reason for leaving (is the price too expensive, or is the plan  not worth for that price, etc), and how can we improve our services.

5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

Personally, I think introducting loyalty program will play a big part to reduce churn rate. We can reward customer that take parts in activities like reviews or referrals, or maybe a simple daily log in to the web.