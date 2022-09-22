-- Author: Elbert Timothy Lasiman

#################################

-- A. Data Cleansing

DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS
SELECT 
	STR_TO_DATE(week_date, '%d/%m/%y') as week_date,
    WEEKOFYEAR(STR_TO_DATE(week_date, '%d/%m/%y')) as week_number,
    MONTH(STR_TO_DATE(week_date, '%d/%m/%y')) as month_number,
    YEAR(STR_TO_DATE(week_date, '%d/%m/%y')) as calendar_year,
    region,
    platform,
    (CASE WHEN segment='null' THEN 'unknown' ELSE segment END) as segment,
    (CASE 
		WHEN segment LIKE '%1%' THEN 'Young Adults'
        WHEN segment LIKE '%2%' THEN 'Middle Aged'
        WHEN segment REGEXP '[34]' THEN 'Retirees' 
        ELSE 'unknown' END) as age_band,
	(CASE 
		WHEN segment LIKE '%C%' THEN 'Couples'
        WHEN segment LIKE '%F%' THEN 'Families'
        ELSE 'unknown' END) as demographic,
    customer_type,
    transactions,
    sales,
    ROUND(sales/transactions, 2) as avg_transactions
FROM weekly_sales
ORDER BY STR_TO_DATE(week_date, '%d/%m/%y');

SELECT * FROM clean_weekly_sales LIMIT 10;

#################################

-- B. Data Exploration

-- Q1: What day of the week is used for each week_date value?
SELECT DISTINCT(DAYNAME(week_date)) as day FROM clean_weekly_sales;

-- Q2: What range of week numbers are missing from the dataset?
-- For this problem, I generated a table that contain number 1-52 (number of week in a year)
DROP TABLE IF EXISTS all_weeks;
CREATE TABLE all_weeks AS
	SELECT ROW_NUMBER() OVER (ORDER BY week_date) as week
	FROM clean_weekly_sales
	LIMIT 52;
SELECT * FROM all_weeks;

SELECT DISTINCT week
FROM clean_weekly_sales
RIGHT JOIN all_weeks
	ON week_number = week
WHERE week_number IS NULL;

-- Q3: How many total transactions were there for each year in the dataset?
SELECT calendar_year, SUM(transactions) as total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year;

-- Q4: What is the total sales for each region for each month?
SELECT region, MONTHNAME(week_date), SUM(sales) as total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

-- Q5: What is the total count of transactions for each platform
SELECT platform, SUM(transactions) as total_transactions_count
FROM clean_weekly_sales
GROUP BY platform;

-- Q6: What is the percentage of sales for Retail vs Shopify for each month?
SELECT 
	s.calendar_year, 
	s.month, 
	retail_sales, 
	shopify_sales, 
	CONCAT(FORMAT(shopify_sales/(retail_sales+shopify_sales)*100, 2), '%') as shopify_sales_percentage, 
	CONCAT(FORMAT(retail_sales/(retail_sales+shopify_sales)*100, 2), '%') as retail_sales_percentage
FROM
	(SELECT calendar_year, MONTHNAME(week_date) as month, SUM(sales) as retail_sales
	FROM clean_weekly_sales
	WHERE platform='Retail'
	GROUP BY calendar_year, month_number) as r
JOIN 
	(SELECT calendar_year, MONTHNAME(week_date) as month, SUM(sales) as shopify_sales
    FROM clean_weekly_sales 
    WHERE platform='shopify' 
    GROUP BY calendar_year, month_number) as s
	ON r.calendar_year = s.calendar_year AND r.month = s.month;
    
-- Q7: What is the percentage of sales by demographic for each year in the dataset?
SELECT 
	calendar_year,
	CONCAT(MAX((CASE WHEN demographic='Families' THEN FORMAT(sales/total_sales*100,0) END)), '%') as families_percentage,
	CONCAT(MAX((CASE WHEN demographic='Couples' THEN FORMAT(sales/total_sales*100,0) END)), '%') as couples_percentage,
	CONCAT(MAX((CASE WHEN demographic='unknown' THEN FORMAT(sales/total_sales*100,0) END)), '%') as unknown_percentage
FROM
	(SELECT s.calendar_year, demographic, SUM(sales) as sales, total_sales
	FROM clean_weekly_sales as s
    JOIN (SELECT calendar_year, SUM(sales) as total_sales FROM clean_weekly_sales GROUP BY calendar_year) as y
		ON y.calendar_year = s.calendar_year
	GROUP BY calendar_year, demographic) as s
GROUP BY calendar_year;

-- Q8: Which age_band and demographic values contribute the most to Retail sales?
SELECT 
	 a.age_band, 
     a.demographic, 
     CONCAT(FORMAT(a.sales/total_sales*100, 1), '%') percentage
FROM clean_weekly_sales as s
JOIN (SELECT SUM(sales) as total_sales FROM clean_weekly_sales) as total_sales
JOIN (SELECT age_band, demographic, SUM(sales) as sales FROM clean_weekly_sales GROUP BY age_band, demographic) as a
	ON s.age_band = a.age_band AND s.demographic = a.demographic
GROUP BY age_band, demographic;

-- Q9: Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
-- If not - how would you calculate it instead?
SELECT 
	calendar_year, 
    platform, 
    FORMAT(SUM(sales)/SUM(transactions), 2) as avg_transactions, 
    FORMAT(AVG(avg_transactions), 2) as avg_of_avg_transactions
FROM clean_weekly_sales
GROUP BY calendar_year, platform;

#################################

-- C. Before & After Analysis

-- Q1: What is the total sales for the 4 weeks before and after 2020-06-15? 
-- What is the growth or reduction rate in actual values and percentage of sales?
SELECT 
	before_change,
	after_change,
    after_change - before_change as reduction_rate,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as reduction_percentage
FROM 
	(SELECT 
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 4) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -3 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales) as t;

-- Q2: What about the entire 12 weeks before and after?
SELECT 
	before_change,
	after_change,
    after_change - before_change as reduction_rate,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as reduction_percentage
FROM 
	(SELECT 
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales) as t;

-- Q3: How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- 4 weeks period
SELECT 
	calendar_year,
	before_june_15,
	after_june_15,
    after_june_15 - before_june_15 as difference,
    CONCAT(FORMAT((after_june_15 - before_june_15) / before_june_15 * 100, 2), '%') as percentage
FROM 
	(SELECT 
		calendar_year,
		SUM(CASE WHEN (WEEK('2020-06-15')-WEEK(week_date) BETWEEN 1 AND 4) THEN sales ELSE 0 END) as before_june_15,
		SUM(CASE WHEN (WEEK('2020-06-15')-WEEK(week_date) BETWEEN -3 AND 0) THEN sales ELSE 0 END) as after_june_15
    FROM clean_weekly_sales
    GROUP BY calendar_year) as t;
    
-- 12 week period
SELECT 
	calendar_year,
	before_june_15,
	after_june_15,
    after_june_15 - before_june_15 as difference,
    CONCAT(FORMAT((after_june_15 - before_june_15) / before_june_15 * 100, 2), '%') as percentage
FROM 
	(SELECT 
		calendar_year,
		SUM(CASE WHEN (WEEK('2020-06-15')-WEEK(week_date) BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_june_15,
		SUM(CASE WHEN (WEEK('2020-06-15')-WEEK(week_date) BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_june_15
    FROM clean_weekly_sales
    GROUP BY calendar_year) as t;
    
#################################

-- D. Bonus Question

-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 
-- for the 12 week before and after period?

-- region

SELECT 
	region,
	before_change,
	after_change,
    after_change - before_change as difference,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as percentage
FROM 
	(SELECT 
		region,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales
    GROUP BY region) as t;

-- platform

SELECT 
	platform,
	before_change,
	after_change,
    after_change - before_change as difference,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as percentage
FROM 
	(SELECT 
		platform,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales
    GROUP BY platform) as t;
    

-- age_band
SELECT 
	age_band,
	before_change,
	after_change,
    after_change - before_change as difference,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as percentage
FROM 
	(SELECT 
		age_band,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales
    GROUP BY age_band) as t;

-- demographic
SELECT 
	demographic,
	before_change,
	after_change,
    after_change - before_change as difference,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as percentage
FROM 
	(SELECT 
		demographic,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales
    GROUP BY demographic) as t;

-- customer_type
SELECT 
	customer_type,
	before_change,
	after_change,
    after_change - before_change as difference,
    CONCAT(FORMAT((after_change - before_change) / before_change * 100, 2), '%') as percentage
FROM 
	(SELECT 
		customer_type,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN 1 AND 12) THEN sales ELSE 0 END) as before_change,
		SUM(CASE WHEN (TIMESTAMPDIFF(WEEK, week_date, '2020-06-15') BETWEEN -11 AND 0) THEN sales ELSE 0 END) as after_change
    FROM clean_weekly_sales
    GROUP BY customer_type) as t;
