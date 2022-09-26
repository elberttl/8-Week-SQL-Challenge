# Case Study #7 - Balanced Tree Clothing Co.

## A. High Level Analysis

1. What was the total quantity sold for all products?
```sql
SELECT SUM(qty) as total_quantity FROM sales;
```
| total_quantity      |
 |  ----------------- |  
| 45216               |

2. What is the total generated revenue for all products before discounts?
```sql
SELECT SUM(qty*price) as revenue_before_discount FROM sales;
```
| revenue_before_discount      |
 |  -------------------------- |  
| 1289453                      |

3. What was the total discount amount for all products?
```sql
SELECT SUM(discount_value) as total_discount
FROM 
	(SELECT qty*price*(discount*0.01) as discount_value FROM sales GROUP BY txn_id) as t;
```
| total_discount      |
 |  ----------------- |  
| 17079.53            |

## B. Transaction Analysis

1. How many unique transactions were there?
```sql
SELECT COUNT(DISTINCT txn_id) as total_txn FROM sales;
```
| total_txn      |
 |  ------------ |  
| 2500           |

2. What is the average unique products purchased in each transaction?
```sql
SELECT ROUND(AVG(unique_prod)) as avg_unique_prod
FROM
	(SELECT COUNT(DISTINCT prod_id) as unique_prod FROM sales GROUP BY txn_id) as t;
```
| avg_unique_prod      |
 |  ------------------ |  
| 6                    |

3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
```sql
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
```
| revenue_after_discount      | percentile      |
 |  ------------------------- |   -------------- |  
| 595.96                      | 0.25            |
| 769.08                      | 0.50            |
| 571.95                      | 0.75            |

4. What is the average discount value per transaction?
```sql
SELECT FORMAT(AVG(discount_value), 2) as avg_discount_value
FROM 
	(SELECT SUM(qty*price*(discount*0.01)) as discount_value FROM sales GROUP BY txn_id) as t;
```
| avg_discount_value      |
 |  --------------------- |  
| 62.49                   |

5. What is the percentage split of all transactions for members vs non-members?
```sql
SELECT member, COUNT(DISTINCT txn_id) as total_txn FROM sales GROUP BY member;
```
| member      | total_txn      |
 |  --------- |   ------------- |  
| 0           | 995            |
| 1           | 1505           |

6. What is the average revenue for member transactions and non-member transactions?
```sql
SELECT member, ROUND(AVG(revenue_after_discount), 2) as avg_revenue
FROM
	(SELECT 
		txn_id,
		member,
		SUM((qty*price)*(1-discount*0.01)) as revenue_after_discount
	FROM sales
	GROUP BY txn_id) as t
GROUP BY member;
```
| member      | avg_revenue      |
 |  --------- |   --------------- |  
| 1           | 454.14           |
| 0           | 452.01           |

## C. Product Analysis

1. What are the top 3 products by total revenue before discount?
```sql
SELECT p.product_id, p.product_name, SUM(s.qty*s.price ) as total_revenue
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY s.prod_id
ORDER BY SUM(s.qty*s.price) DESC;
```
| product_id      | product_name      | total_revenue      |
 |  ------------- |   ---------------- |   ----------------- |  
| 2a2353          | Blue Polo Shirt - Mens | 217683             |
| 9ec847          | Grey Fashion Jacket - Womens | 209304             |
| 5d267b          | White Tee Shirt - Mens | 152000             |
| f084eb          | Navy Solid Socks - Mens | 136512             |
| e83aa3          | Black Straight Jeans - Womens | 121152             |
| 2feb6b          | Pink Fluro Polkadot Socks - Mens | 109330             |
| d5e9a6          | Khaki Suit Jacket - Womens | 86296              |
| 72f5d4          | Indigo Rain Jacket - Womens | 71383              |
| b9a74d          | White Striped Socks - Mens | 62135              |
| c4a632          | Navy Oversized Jeans - Womens | 50128              |
| e31d39          | Cream Relaxed Jeans - Womens | 37070              |
| c8d436          | Teal Button Up Shirt - Mens | 36460              |

2. What is the total quantity, revenue and discount for each segment?
```sql
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
```
| segment_id      | segment_name      | total_qty      | total_revenue      | total_discount      |
 |  ------------- |   ---------------- |   ------------- |   ----------------- |   ------------------ |  
| 3               | Jeans             | 11349          | 208350             | 25344               |
| 4               | Jacket            | 11385          | 366983             | 44277               |
| 5               | Shirt             | 11265          | 406143             | 49594               |
| 6               | Socks             | 11217          | 307977             | 37013               |

3. What is the top selling product for each segment?
```sql
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
```
| segment_id      | product_name      | total_qty      |
 |  ------------- |   ---------------- |   ------------- |  
| 3               | Navy Oversized Jeans - Womens | 3856           |
| 4               | Grey Fashion Jacket - Womens | 3876           |
| 5               | Blue Polo Shirt - Mens | 3819           |
| 6               | Navy Solid Socks - Mens | 3792           |

4. What is the total quantity, revenue and discount for each category?
```sql
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
```
| category_id      | category_name      | total_qty      | total_revenue      | total_discount      |
 |  -------------- |   ----------------- |   ------------- |   ----------------- |   ------------------ |  
| 1                | Womens             | 22734          | 575333             | 69621               |
| 2                | Mens               | 22482          | 714120             | 86608               |

5. What is the top selling product for each category?
```sql
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
```
| category_id      | category_name      | product_name      | total_qty      |
 |  -------------- |   ----------------- |   ---------------- |   ------------- |  
| 1                | Womens             | Grey Fashion Jacket - Womens | 3876           |
| 2                | Mens               | Blue Polo Shirt - Mens | 3819           |

6. What is the percentage split of revenue by product for each segment?
```sql
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
```
| segment_id      | product_name      | revenue_after_disc      | total_revenue      | percentage      |
 |  ------------- |   ---------------- |   ---------------------- |   ----------------- |   -------------- |  
| 3               | Black Straight Jeans - Womens | 106407                  | 183006             | 58%             |
| 3               | Navy Oversized Jeans - Womens | 43992                   | 183006             | 24%             |
| 3               | Cream Relaxed Jeans - Womens | 32607                   | 183006             | 18%             |
| 4               | Grey Fashion Jacket - Womens | 183912                  | 322705             | 57%             |
| 4               | Khaki Suit Jacket - Womens | 76053                   | 322705             | 24%             |
| 4               | Indigo Rain Jacket - Womens | 62740                   | 322705             | 19%             |
| 5               | Blue Polo Shirt - Mens | 190864                  | 356548             | 54%             |
| 5               | White Tee Shirt - Mens | 133622                  | 356548             | 37%             |
| 5               | Teal Button Up Shirt - Mens | 32062                   | 356548             | 9%              |
| 6               | Navy Solid Socks - Mens | 119862                  | 270964             | 44%             |
| 6               | Pink Fluro Polkadot Socks - Mens | 96378                   | 270964             | 36%             |
| 6               | White Striped Socks - Mens | 54724                   | 270964             | 20%             |

7. What is the percentage split of revenue by segment for each category?
```sql
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
```
| category_name      | segment_name      | revenue_after_disc      | total_revenue      | percentage      |
 |  ---------------- |   ---------------- |   ---------------------- |   ----------------- |   -------------- |  
| Womens             | Jeans             | 183006                  | 505712             | 36%             |
| Womens             | Jacket            | 322706                  | 505712             | 64%             |
| Mens               | Shirt             | 356549                  | 627513             | 57%             |
| Mens               | Socks             | 270964                  | 627513             | 43%             |

8. What is the percentage split of total revenue by category?
```sql
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
```
| category_name      | revenue_after_disc      | total_revenue      | percentage      |
 |  ---------------- |   ---------------------- |   ----------------- |   -------------- |  
| Mens               | 627512                  | 1133224            | 55%             |
| Womens             | 505712                  | 1133224            | 45%             |

9.  What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```sql
SELECT
	p.product_name, 
    SUM(qty>1) as total_txn_product_purchased,
	CONCAT(ROUND(SUM(qty>1)/COUNT(DISTINCT txn_id)*100, 2), '%') as penetration
FROM sales as s
JOIN product_details as p
	ON s.prod_id = p.product_id
GROUP BY s.prod_id;
```
| product_name      | total_txn_product_purchased      | penetration      |
 |  --------------- |   ------------------------------- |   --------------- |  
| Blue Polo Shirt - Mens | 1028                             | 81.07%           |
| Pink Fluro Polkadot Socks - Mens | 1011                             | 80.37%           |
| White Tee Shirt - Mens | 1010                             | 79.65%           |
| Indigo Rain Jacket - Womens | 1005                             | 80.40%           |
| Grey Fashion Jacket - Womens | 1030                             | 80.78%           |
| White Striped Socks - Mens | 962                              | 77.39%           |
| Navy Oversized Jeans - Womens | 1031                             | 80.93%           |
| Teal Button Up Shirt - Mens | 974                              | 78.42%           |
| Khaki Suit Jacket - Womens | 1004                             | 80.51%           |
| Cream Relaxed Jeans - Womens | 990                              | 79.65%           |
| Black Straight Jeans - Womens | 1003                             | 80.50%           |
| Navy Solid Socks - Mens | 996                              | 77.75%           |

10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

```sql
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
```
| combination      | combination_name      | count      |
 |  -------------- |   -------------------- |   --------- |  
| 5d267b, 9ec847, c8d436 | White Tee Shirt - Mens, Grey Fashion Jacket - Womens, Teal Button Up Shirt - Mens | 352        |

For this problem, I generated all the possible combination of 3 from all 12 products.

## D. Reporting Challenge
Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

```sql
SET @monthSales:= 'January';
SET @yearSales:= 2021;
DROP TABLE IF EXISTS sales_monthly;
CREATE TABLE sales_monthly AS
(SELECT * FROM sales
WHERE MONTHNAME(start_txn_time)=@monthSales AND YEAR(start_txn_time)=@yearSales);
SELECT * FROM sales_monthly;
```

For this problem, I created a new table named `sales_monthly` where the transactions are filtered to only the desired month and year. Then, we can use all the queries from Part C again, but replacing `sales` table with `sales_monthly`. The month and year variables then can be updated to the desired value.

## E. Bonus Challenge

Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

Hint: you may want to consider using a recursive CTE to solve this problem!

```sql
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
```