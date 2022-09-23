# Case Study #1 - Danny's Diner

- [Case Study #1 - Danny's Diner](#case-study-1---dannys-diner)
  - [Case Study Questions](#case-study-questions)
  - [Bonus Questions](#bonus-questions)
    - [Join All The Things](#join-all-the-things)
    - [Rank All The Things](#rank-all-the-things)

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?

```sql
SELECT 
    sales.customer_id, SUM(menu.price) AS `total spent`
FROM
    sales, menu
WHERE
    sales.product_id = menu.product_id
GROUP BY customer_id;
```

| customer_id      | total spent      |
| ---------------- | ---------------- |
| A                | 76               |
| B                | 74               |
| C                | 36               |

Customer A and B has roughly the same amount of total spent, while customer C has the least amount of total spent.

2. How many days has each customer visited the restaurant?

```sql
SELECT 
    customer_id, COUNT(DISTINCT order_date) as days
FROM
    sales
GROUP BY customer_id;
```

| customer_id      | days      |
| ---------------- | ------------------------------- |
| A                | 4                               |
| B                | 6                               |
| C                | 2                               |

Customer B regularly visit the dinner.

3. What was the first item from the menu purchased by each customer?

```sql
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
```

| customer_id      | first purchases      |
| ---------------- | -------------------- |
| A                | sushi,curry          |
| B                | curry                |
| C                | ramen,ramen          |

On their first purchases, customer A ordered sushi and curry, customer B ordered curry, while customer C order 2 ramen.

4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
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
```
| product_name      | purchased      |
| ----------------- | -------------- |
| ramen             | 8              |

Ramen is the favorite dish on the menu.

5. Which item was the most popular for each customer?

```sql
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
```

| customer_id      | popular_product      |
| ---------------- | -------------------- |
| A                | ramen                |
| B                | curry,ramen,sushi    |
| C                | ramen                |

All customers most often purchase ramen, except customer B purchases all products equally. 


6. Which item was purchased first by the customer after they became a member?

```sql
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
```

| customer_id      | purchases_after_member      |
| ---------------- | --------------------------- |
| A                | curry                       |
| B                | sushi                       |

Customer A purchased curry, while customer B purchased sushi after they became members.

7. Which item was purchased just before the customer became a member?

```sql
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
```

| customer_id      | purchases_before_member      |
| ---------------- | ---------------------------- |
| A                | sushi,curry                  |
| B                | sushi                        |

Before becaming a member, customer A purchased sushi and curry, while customer B purchased sushi.

8. What is the total items and amount spent for each member before they became a member?

```sql
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
```

| customer_id      | total purchases      | total spent      |
| ---------------- | -------------------- | ---------------- |
| A                | 2                    | 25               |
| B                | 3                    | 40               |

9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
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
```

| customer_id      | total points      |
| ---------------- | ----------------- |
| A                | 860               |
| B                | 940               |
| C                | 360               |

B has the most points. And excepted, C has the least points because their spending is the lowest and their favorite item is ramen. 

10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
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
```

| customer_id      | total points      |
| ---------------- | ----------------- |
| A                | 1370              |
| B                | 820               |

## Bonus Questions

### Join All The Things
```sql
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
```

| customer_id      | order_date      | product_name      | price      | member      |
| ---------------- | --------------- | ----------------- | ---------- | ----------- |
| A                | 2021-01-01      | sushi             | 10         | N           |
| A                | 2021-01-01      | curry             | 15         | N           |
| A                | 2021-01-07      | curry             | 15         | Y           |
| A                | 2021-01-10      | ramen             | 12         | Y           |
| A                | 2021-01-11      | ramen             | 12         | Y           |
| A                | 2021-01-11      | ramen             | 12         | Y           |
| B                | 2021-01-01      | curry             | 15         | N           |
| B                | 2021-01-02      | curry             | 15         | N           |
| B                | 2021-01-04      | sushi             | 10         | N           |
| B                | 2021-01-11      | sushi             | 10         | Y           |
| B                | 2021-01-16      | ramen             | 12         | Y           |
| B                | 2021-02-01      | ramen             | 12         | Y           |
| C                | 2021-01-01      | ramen             | 12         | N           |
| C                | 2021-01-01      | ramen             | 12         | N           |
| C                | 2021-01-07      | ramen             | 12         | N           |

### Rank All The Things
```sql
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
```

| customer_id      | order_date      | product_name      | price      | member      | ranking      |
| ---------------- | --------------- | ----------------- | ---------- | ----------- | ------------ |
| A                | 2021-01-01      | sushi             | 10         | N           |              |
| A                | 2021-01-01      | curry             | 15         | N           |              |
| A                | 2021-01-07      | curry             | 15         | Y           | 1            |
| A                | 2021-01-10      | ramen             | 12         | Y           | 2            |
| A                | 2021-01-11      | ramen             | 12         | Y           | 3            |
| A                | 2021-01-11      | ramen             | 12         | Y           | 3            |
| B                | 2021-01-01      | curry             | 15         | N           |              |
| B                | 2021-01-02      | curry             | 15         | N           |              |
| B                | 2021-01-04      | sushi             | 10         | N           |              |
| B                | 2021-01-11      | sushi             | 10         | Y           | 1            |
| B                | 2021-01-16      | ramen             | 12         | Y           | 2            |
| B                | 2021-02-01      | ramen             | 12         | Y           | 3            |
| C                | 2021-01-01      | ramen             | 12         | N           |              |
| C                | 2021-01-01      | ramen             | 12         | N           |              |
| C                | 2021-01-07      | ramen             | 12         | N           |              |