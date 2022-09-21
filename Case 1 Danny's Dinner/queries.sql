-- Author: Elbert Timothy Lasiman

-- --------------------------------------

-- Q1: What is the total amount each customer spent at the restaurant?
SELECT 
    sales.customer_id, SUM(menu.price) AS `total spent`
FROM
    sales, menu
WHERE
    sales.product_id = menu.product_id
GROUP BY customer_id;

-- Q2: How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) as days
FROM
    sales
GROUP BY customer_id;

-- Q3: What was the first item from the menu purchased by each customer?
SELECT customer_id, GROUP_CONCAT(product_name) as `first purchases`
FROM (
	SELECT 
		sales.customer_id, 
        menu.product_name, 
        RANK() OVER(PARTITION BY sales.customer_id ORDER BY sales.order_date) AS top1 
    FROM sales, menu
    WHERE sales.product_id = menu.product_id
) AS first_item
WHERE top1 = 1
GROUP BY customer_id;

-- Q4: What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    menu.product_name, COUNT(sales.product_id) AS `purchased`
FROM
    sales,
    menu
WHERE
    sales.product_id = menu.product_id
GROUP BY sales.product_id
ORDER BY `purchased` DESC
LIMIT 1;
    
-- Q5: Which item was the most popular for each customer?
SELECT 
    customer_id, GROUP_CONCAT(DISTINCT product_name) AS popular_product
FROM
    (SELECT 
		sales.customer_id, 
		menu.product_name, 
		RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) as top1
    FROM
        sales, menu
    WHERE
        sales.product_id = menu.product_id
    GROUP BY customer_id , product_name
) AS popular_product
WHERE top1 = 1
GROUP BY customer_id;

-- Q:6 Which item was purchased first by the customer after they became a member?
SELECT customer_id, GROUP_CONCAT(product_name) as purchases_after_member
FROM (
	SELECT
		sales.customer_id, 
        sales.order_date, 
        menu.product_name,
        RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as top1
	FROM
		sales,
		menu,
		members
	WHERE
		sales.order_date >= members.join_date
			AND sales.customer_id = members.customer_id
			AND sales.product_id = menu.product_id
) AS first_member_purchases
WHERE top1 = 1
GROUP BY customer_id;
    
-- Q7: Which item was purchased just before the customer became a member?
SELECT customer_id, GROUP_CONCAT(product_name) as purchases_before_member
FROM 
	(SELECT
		sales.customer_id, 
        menu.product_name,
        RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as top1
	FROM
		sales,
		menu,
		members
	WHERE
		sales.order_date < members.join_date
			AND sales.customer_id = members.customer_id
			AND sales.product_id = menu.product_id
) AS before_member_purchases
WHERE top1 = 1 
GROUP BY customer_id;

-- Q8: What is the total items and amount spent for each member before they became a member?
SELECT
	sales.customer_id,
    COUNT(sales.product_id) AS `total purchases`,
    SUM(menu.price) AS `total spent`
FROM sales, menu, members
WHERE sales.order_date < members.join_date
        AND sales.customer_id = members.customer_id
		AND sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- Q9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    sales.customer_id,
    SUM(CASE 
			WHEN menu.product_name LIKE 'sushi'
			THEN menu.price * 20
			ELSE menu.price * 10 
		END) AS `total points`
FROM
    sales,
    menu
WHERE
    sales.product_id = menu.product_id
GROUP BY customer_id;

-- Q10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT 
    sales.customer_id,
    SUM(CASE
			WHEN menu.product_name LIKE 'sushi' 
            THEN menu.price * 20
			ELSE menu.price * 10
		END *
		CASE 
			WHEN 
				sales.order_date-members.join_date BETWEEN 0 AND 6 
				AND menu.product_name NOT LIKE 'sushi'
			THEN 2 
            ELSE 1 
		END) AS `total points`
FROM
    sales,
    menu,
    members
WHERE
    sales.product_id = menu.product_id
    AND sales.customer_id = members.customer_id
    AND sales.order_date < '2021-02-01'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- --------------------------------------

-- BONUS QUESTION

-- Join All Things
SELECT 
	sales.customer_id, 
    sales.order_date, 
    menu.product_name, 
    menu.price,
    (CASE WHEN sales.order_date >= members.join_date THEN 'Y' ELSE 'N' END) AS member
FROM sales
JOIN menu
	ON sales.product_id = menu.product_id
LEFT JOIN members
	ON sales.customer_id = members.customer_id;

-- Rank All The Things
SELECT 
	customer_id, 
	order_date, 
    product_name, 
    price, 
    member, 
    (CASE WHEN order_date >= join_date 
    THEN DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
    ELSE null 
    END) AS ranking 
FROM
	(SELECT 
		sales.customer_id AS customer_id, 
		sales.order_date AS order_date, 
		menu.product_name AS product_name, 
		menu.price AS price,
		(CASE WHEN sales.order_date >= members.join_date THEN 'Y' ELSE 'N' END) AS member,
        members.join_date AS join_date
	FROM sales
	JOIN menu
		ON sales.product_id = menu.product_id
	LEFT JOIN members
		ON sales.customer_id = members.customer_id
	) AS all_things;