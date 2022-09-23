-- Author: Elbert Timothy Lasiman

#################################

-- B. Digital Analysis

-- Q1: How many users are there?
SELECT COUNT(DISTINCT(user_id)) as user_count from users;

-- Q2: How many cookies does each user have on average?
SELECT AVG(count_cookie) as average_cookie
FROM 
	(SELECT COUNT(cookie_id) as count_cookie FROM users GROUP BY user_id) as t; 
-- or without subquery
SELECT AVG(COUNT(cookie_id)) OVER() as average_cookie FROM users GROUP BY user_id LIMIT 1; 

-- Q3: What is the unique number of visits by all users per month?
SELECT MONTHNAME(event_time) as month, COUNT(DISTINCT visit_id) as number_of_visit
FROM events
GROUP BY MONTHNAME(event_time)
ORDER BY MONTH(event_time);

-- Q4: What is the number of events for each event type?
SELECT e.event_type, i.event_name, COUNT(e.event_type) as count 
FROM events  as e
JOIN event_identifier as i
	ON e.event_type = i.event_type
GROUP BY event_type;

-- Q5: What is the percentage of visits which have a purchase event?
SELECT i.event_name, CONCAT(FORMAT(COUNT(DISTINCT visit_id)/total_event*100, 0), '%') as percentage
FROM events as e
JOIN event_identifier as i
	ON e.event_type = i.event_type AND i.event_name = "Purchase"
JOIN (SELECT COUNT(DISTINCT visit_id) as total_event FROM events) as t
GROUP BY e.event_type;

-- Q6: What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT 
	COUNT(DISTINCT no_purchases) as no_purchases, 
	COUNT(DISTINCT purchased) as purchased, 
    CONCAT(FORMAT(COUNT(DISTINCT no_purchases)/(COUNT(DISTINCT no_purchases)+COUNT(DISTINCT purchased))*100, 1), '%') as no_purchases_percentage
FROM 
	(SELECT visit_id as no_purchases
    FROM events 
    GROUP BY visit_id
	HAVING
		SUM(event_type = 1 AND page_id = 12) > 0 AND
        SUM(event_type = 3) = 0) as t,
	(SELECT visit_id as purchased
    FROM events 
    GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 1) as tt;

-- Q7: What are the top 3 pages by number of views?
SELECT page_name, COUNT(visit_id) as view_count 
FROM events as e
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
GROUP BY page_name
ORDER BY COUNT(visit_id) DESC;

-- Q8: What is the number of views and cart adds for each product category?
SELECT product_category, SUM(event_name = 'Page View') as page_view, SUM(event_name = 'Add to Cart') as cart_adds
FROM events as e
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
JOIN event_identifier as i
	ON e.event_type = i.event_type
WHERE p.product_category IS NOT NULL
GROUP BY product_category;

-- Q9: What are the top 3 products by purchases?
SELECT page_name, COUNT(page_name) as purchases_count
FROM events as e
JOIN -- subquery to filter visitor who purchased products
	(SELECT visit_id
	FROM events 
	GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 1) as purchased
	ON purchased.visit_id = e.visit_id
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
JOIN event_identifier as i
	ON e.event_type = i.event_type
WHERE event_name = 'Add to Cart' -- filter the products that are added to cart
GROUP BY page_name
ORDER BY COUNT(page_name) DESC;

#################################

-- C. Product Funnel Analysis
-- Using a single SQL query - create a new output table which has the following details:
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?

DROP TABLE IF EXISTS product_statistics;
CREATE TABLE product_statistics AS
(SELECT 
	DISTINCT page_name, 
    SUM(event_type=1) OVER(PARTITION BY page_name) as viewed,
    SUM(event_type=2) OVER(PARTITION BY page_name) as add_to_cart,
    SUM(purchased.stat='purchased' AND event_type=2) OVER(PARTITION BY page_name) as purchases,
    SUM(abandoned.stat='abandoned' AND event_type=2) OVER(PARTITION BY page_name) as abandoned
FROM events as e
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
LEFT JOIN -- subquery to filter visitor who purchased products
	(SELECT visit_id, 'purchased' as stat
	FROM events 
	GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 1) as purchased
	ON purchased.visit_id = e.visit_id
LEFT JOIN -- subquery to filter visitor who abandoned purchases
	(SELECT visit_id, 'abandoned' as stat
	FROM events 
	GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 0) as abandoned
	ON abandoned.visit_id = e.visit_id
WHERE product_id IS NOT NULL);
SELECT * FROM product_statistics;

-- Additionally, create another table which further aggregates the data for the above points 
-- but this time for each product category instead of individual products.
DROP TABLE IF EXISTS category_statistics;
CREATE TABLE category_statistics AS
(SELECT 
	DISTINCT product_category, 
    SUM(event_type=1) OVER(PARTITION BY product_category) as viewed,
    SUM(event_type=2) OVER(PARTITION BY product_category) as add_to_cart,
    SUM(purchased.stat='purchased' AND event_type=2) OVER(PARTITION BY product_category) as purchases,
    SUM(abandoned.stat='abandoned' AND event_type=2) OVER(PARTITION BY product_category) as abandoned
FROM events as e
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
LEFT JOIN -- subquery to filter visitor who purchased products
	(SELECT visit_id, 'purchased' as stat
	FROM events 
	GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 1) as purchased
	ON purchased.visit_id = e.visit_id
LEFT JOIN -- subquery to filter visitor who abandoned purchases
	(SELECT visit_id, 'abandoned' as stat
	FROM events 
	GROUP BY visit_id
	HAVING
        SUM(event_type = 3) = 0) as abandoned
	ON abandoned.visit_id = e.visit_id
WHERE product_id IS NOT NULL);
SELECT * FROM category_statistics;

-- Q1: Which product had the most views, cart adds and purchases?
-- &
-- Q2: Which product was most likely to be abandoned
SELECT *,
	(CASE WHEN viewed = MAX(viewed) OVER() THEN 'max_viewed' ELSE ''END) as max_viewed,
	(CASE WHEN add_to_cart = MAX(add_to_cart) OVER() THEN 'max_add_to_cart' ELSE ''END) as max_add_to_cart,
	(CASE WHEN purchases = MAX(purchases) OVER() THEN 'max_purchases' ELSE '' END) as max_purchases,
	(CASE WHEN abandoned = MAX(abandoned) OVER() THEN 'max_abandoned' ELSE ''END) as max_abandoned
FROM product_statistics;

-- Q3: Which product had the highest view to purchase percentage?
SELECT *,
	CONCAT(FORMAT(purchases/viewed*100,2),'%') as view_to_purchases
FROM product_statistics
ORDER BY purchases/viewed DESC;

-- Q4: What is the average conversion rate from view to cart add?
-- &
-- Q5: What is the average conversion rate from cart add to purchase?
SELECT
	CONCAT(FORMAT(AVG(add_to_cart/viewed*100),2),'%') as avg_view_to_cart_adds,
	CONCAT(FORMAT(AVG(purchases/add_to_cart*100),2),'%') as avg_view_to_cart_adds
FROM product_statistics
ORDER BY purchases/viewed DESC;

#################################

-- D. Campaigns Analysis
DROP TABLE IF EXISTS event_campaign;
CREATE TABLE event_campaign AS
(SELECT
	user_id,
	visit_id, 
    MIN(event_time) as visit_start_time,
    SUM(event_name='Page View') as page_views,
    SUM(event_name='Add to Cart') as cart_adds,
    SUM(event_name='Purchase') as purchase,
    IFNULL(campaign_name, '') as campaign_name,
    SUM(event_name='Ad Impression') as impression,
    SUM(event_name='Ad Click') as click,
    IFNULL(GROUP_CONCAT(
		CASE WHEN event_name='Add to Cart'  THEN page_name END 
        ORDER BY sequence_number 
        SEPARATOR ', '), '') as cart_products
FROM events as e
JOIN users as u
	ON u.cookie_id = e.cookie_id
LEFT JOIN campaign_identifier as c
	ON event_time BETWEEN c.start_date AND c.end_date
JOIN event_identifier as i
	ON i.event_type = e.event_type
JOIN page_hierarchy as p
	ON p.page_id = e.page_id
GROUP BY visit_id
ORDER BY event_time);

SELECT * FROM event_campaign;

SELECT 
	e.campaign_name,
    IFNULL(DATEDIFF(end_date, start_date),
		148-(13+13+59)) as campaign_days, -- 148 is hardcoded from events.event_time range
    COUNT(*) as visit_count,
	FORMAT(COUNT(*)/IFNULL(DATEDIFF(end_date, start_date),
		148-(13+13+59)),0) as avg_visit_per_day,
    FORMAT(AVG(page_views), 2) as avg_page_views,
    FORMAT(AVG(cart_adds), 2) as avg_cart_adds,
    FORMAT(AVG(purchase), 2) as avg_purchases
FROM event_campaign as e
LEFT JOIN campaign_identifier as c
	ON e.campaign_name = c.campaign_name
GROUP BY e.campaign_name;

SELECT 
	campaign_name,
	impression,
    FORMAT(AVG(page_views), 2) as avg_page_views,
    FORMAT(AVG(cart_adds), 2) as avg_cart_adds,
    FORMAT(AVG(purchase), 2) as avg_purchases
FROM event_campaign
GROUP BY campaign_name, impression;

SELECT 
	campaign_name,
	click,
    FORMAT(AVG(page_views), 2) as avg_page_views,
    FORMAT(AVG(cart_adds), 2) as avg_cart_adds,
    FORMAT(AVG(purchase), 2) as avg_purchases
FROM event_campaign
WHERE impression = 1
GROUP BY campaign_name, click;

SELECT 
	*
FROM (AVG(page_views) FROM event_campaign WHERE impression=0) as ;

SELECT * FROM campaign_identifier;
SELECT * FROM events as e 
JOIN event_identifier as i
	ON e.event_type=i.event_type
WHERE visit_id='0fc437';
SELECT * FROM event_identifier;

SELECT *, DATEDIFF(end_date, start_date) FROM campaign_identifier;
SELECT MAX(visit_start_time) FROM event_campaign;
SELECT DATEDIFF('2020-05-28 20:11:55','2020-01-01 07:44:57');