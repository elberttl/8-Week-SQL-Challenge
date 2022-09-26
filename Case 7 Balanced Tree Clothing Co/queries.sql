-- Author: Elbert Timothy Lasiman

#################################

-- A. High Level Sales Analysis

-- Q1: What was the total quantity sold for all products?
SELECT SUM(qty) as total_quantity FROM sales;

-- Q2: What is the total generated revenue for all products before discounts?
SELECT SUM(qty*price) as revenue_before_discount FROM sales;

-- Q3: What was the total discount amount for all products?
-- Notes: discount column is in percentage
SELECT SUM(discount_value) as total_discount
FROM 
	(SELECT qty*price*(discount*0.01) as discount_value FROM sales GROUP BY txn_id) as t;

#################################

-- B. Transaction Analysis

-- Q1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) as total_txn FROM sales;

-- Q2: What is the average unique products purchased in each transaction?
SELECT ROUND(AVG(unique_prod)) as avg_unique_prod
FROM
	(SELECT COUNT(DISTINCT prod_id) as unique_prod FROM sales GROUP BY txn_id) as t;

-- Q3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT 
	revenue_after_discount,
    FORMAT(n_row/total_txn, 2) as percentile
FROM
	(SELECT 
		SUM((qty*price)*(1-discount*0.01)) as revenue_after_discount,
		ROW_NUMBER() OVER(ORDER BY (qty*price)*(1-discount*0.01)) as n_row,
        total_txn
	FROM sales 
    JOIN (SELECT COUNT(DISTINCT txn_id) as total_txn FROM sales) as total_txn
    GROUP BY txn_id) as t
WHERE 
	n_row = ROUND((total_txn)*0.25) -- 25th percentile
	OR n_row = ROUND((total_txn*0.5)) -- median / 50th percentile
    OR n_row = ROUND((total_txn)*0.75); -- 75th percentile;

-- Q4: What is the average discount value per transaction?
SELECT FORMAT(AVG(discount_value), 2) as avg_discount_value
FROM 
	(SELECT SUM(qty*price*(discount*0.01)) as discount_value FROM sales GROUP BY txn_id) as t;

-- Q5: What is the percentage split of all transactions for members vs non-members?
SELECT member, COUNT(DISTINCT txn_id) as total_txn FROM sales GROUP BY member;

-- Q6: What is the average revenue for member transactions and non-member transactions?
SELECT member, ROUND(AVG(revenue_after_discount), 2) as avg_revenue
FROM
	(SELECT 
		txn_id,
		member,
		SUM((qty*price)*(1-discount*0.01)) as revenue_after_discount
	FROM sales
	GROUP BY txn_id) as t
GROUP BY member;

#################################

-- C. Product Analysis

-- Q1: What are the top 3 products by total revenue before discount?
SELECT p.product_id, p.product_name, SUM(s.qty*s.price ) as total_revenue
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY s.prod_id
ORDER BY SUM(s.qty*s.price) DESC;

-- Q2: What is the total quantity, revenue and discount for each segment?
SELECT 
	p.segment_id, 
    p.segment_name, 
    SUM(s.qty) as total_qty,
    SUM(s.qty*s.price) as total_revenue,
    ROUND(SUM(s.qty*s.price*s.discount*0.01)) as total_discount
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY p.segment_id
ORDER BY p.segment_id;

-- Q3: What is the top selling product for each segment?
SELECT segment_id, product_name, total_qty
FROM
	(SELECT 
		p.segment_id, 
		p.product_name, 
		SUM(s.qty) as total_qty,
		RANK() OVER(PARTITION BY segment_id ORDER BY SUM(s.qty) DESC) as rn
	FROM sales as s
	JOIN product_details as p
		ON s.prod_id = p.product_id
	GROUP BY p.product_id
	ORDER BY p.segment_id, total_qty DESC) as t
WHERE rn=1;

-- Q4: What is the total quantity, revenue and discount for each category?
SELECT 
	p.category_id, 
    p.category_name, 
    SUM(s.qty) as total_qty,
    SUM(s.qty*s.price) as total_revenue,
    ROUND(SUM(s.qty*s.price*s.discount*0.01)) as total_discount
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY p.category_id
ORDER BY p.category_id;

-- Q5: What is the top selling product for each category?
SELECT category_id, category_name, product_name, total_qty
FROM
	(SELECT 
		p.category_id,
        p.category_name,
		p.product_name, 
		SUM(s.qty) as total_qty,
		RANK() OVER(PARTITION BY category_id ORDER BY SUM(s.qty) DESC) as rn
	FROM sales as s
	JOIN product_details as p
		ON s.prod_id = p.product_id
	GROUP BY p.product_id
	ORDER BY p.category_id, total_qty DESC) as t
WHERE rn=1;

-- Q6: What is the percentage split of revenue by product for each segment?
SELECT 
	p.segment_id, 
	p.product_name, 
	ROUND(SUM(s.qty*s.price*(1-s.discount*0.01))) as revenue_after_disc,
    SUM(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)))) OVER(PARTITION BY segment_id) as total_revenue,
    CONCAT(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)) 
		/ SUM(SUM(s.qty*s.price*(1-s.discount*0.01)))  OVER(PARTITION BY segment_id) * 100), '%') as percentage
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY p.product_id
ORDER BY p.segment_id, revenue_after_disc DESC;

-- Q7: What is the percentage split of revenue by segment for each category?
SELECT 
	p.category_name, 
	p.segment_name, 
	ROUND(SUM(s.qty*s.price*(1-s.discount*0.01))) as revenue_after_disc,
    SUM(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)))) OVER(PARTITION BY category_id) as total_revenue,
    CONCAT(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)) 
		/ SUM(SUM(s.qty*s.price*(1-s.discount*0.01)))  OVER(PARTITION BY category_id) * 100), '%') as percentage
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY p.segment_id
ORDER BY p.segment_id, revenue_after_disc DESC;

-- Q8: What is the percentage split of total revenue by category?
SELECT 
	p.category_name,
	ROUND(SUM(s.qty*s.price*(1-s.discount*0.01))) as revenue_after_disc,
    SUM(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)))) OVER() as total_revenue,
    CONCAT(ROUND(SUM(s.qty*s.price*(1-s.discount*0.01)) 
		/ SUM(SUM(s.qty*s.price*(1-s.discount*0.01)))  OVER() * 100), '%') as percentage
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY p.category_id
ORDER BY revenue_after_disc DESC;

-- Q9: What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased 
-- divided by total number of transactions)
SELECT
	p.product_name, 
    SUM(qty>1) as total_txn_product_purchased,
	CONCAT(ROUND(SUM(qty>1)/COUNT(DISTINCT txn_id)*100, 2), '%') as penetration
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY s.prod_id;

-- Q10: What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
-- Generate combinations of 3 products, https://stackoverflow.com/questions/4159595/how-to-generate-a-permutations-or-combinations-of-n-rows-in-m-columns
SELECT
    CONCAT_WS(', ', c1.product_id, c2.product_id, c3.product_id) as combination,
    CONCAT_WS(', ', c1.product_name, c2.product_name, c3.product_name) as combination_name,
	SUM(
		product_comb LIKE CONCAT('%',(c1.product_id),'%')
        AND product_comb LIKE CONCAT('%',(c2.product_id),'%')
        AND product_comb LIKE CONCAT('%',(c3.product_id),'%')) as count
FROM product_details as c1
JOIN (SELECT product_id, product_name FROM product_details) as c2
	ON c1.product_id < c2.product_id
JOIN (SELECT product_id, product_name FROM product_details) as c3
	ON c1.product_id < c3.product_id AND c2.product_id < c3.product_id
JOIN (SELECT GROUP_CONCAT(prod_id) as product_comb FROM sales GROUP BY txn_id) as comb
GROUP BY c1.product_id, c2.product_id, c3.product_id
ORDER BY count DESC
LIMIT 1;

#################################

-- D. Reporting Challenge
-- I'll make a new table from sales table that will filter the transactions only for that month.
SET @monthSales:= 'January';
SET @yearSales:= 2021;
DROP TABLE IF EXISTS sales_monthly;
CREATE TABLE sales_monthly AS
(SELECT * FROM sales
WHERE MONTHNAME(start_txn_time)=@monthSales AND YEAR(start_txn_time)=@yearSales);
SELECT * FROM sales_monthly;

-- Now, we can just rewrite all the above queries, and just replace sales table with sales_monthly table. For different month,
-- update @monthSales and @yearSales to the desired month and year.
-- I won't rewrite the queries from the previous challenge, so that this script is not too long

#################################

-- E. Bonus Challenge
-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!
WITH RECURSIVE re AS
(
	SELECT id, parent_id, level_text, level_name
    FROM product_hierarchy
    WHERE parent_id IS NULL
    
    UNION ALL
    
    SELECT p.id, p.parent_id, p.level_text, p.level_name
    FROM product_hierarchy as p, re
	WHERE p.parent_id = re.id
)

SELECT 
	product_id,
    price,
    CONCAT(p.level_text,' ', 
		re.level_text,' - ', 
        (CASE WHEN p.parent_id=1 THEN 'Womens' ELSE 'Mens' END)) as product_name,
    p.parent_id as category_id,
	re.parent_id as segment_id,
    re.id as style_id,
    (CASE WHEN p.parent_id=1 THEN 'Womens' ELSE 'Mens' END) as category_name,
    p.level_text as segment_name,
    re.level_text as style_name
FROM re
LEFT JOIN product_hierarchy as p
	ON re.parent_id = p.id
LEFT JOIN product_prices as pp
	ON re.id = pp.id
WHERE p.parent_id IS NOT NULL
ORDER BY style_id;

#################################
