# Case Study #2 - Pizza Runner

## A. Pizza Metrics
1. How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) AS ordered_pizza FROM customer_orders;
```

| ordered_pizza      |
| ------------------ |
| 14                 |

14 pizza were ordered.

2. How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) AS unique_orders FROM customer_orders;
```

| unique_orders      |
| ------------------ |
| 10                 |

10 unique orders were made.

3. How many successful orders were delivered by each runner?

```sql
SELECT 
	runner_id, 
	COUNT(order_id) AS successful_order
FROM runner_orders
WHERE pickup_time != 'null'
GROUP BY runner_id;
```

| runner_id      | successful_order      |
| -------------- | --------------------- |
| 1              | 4                     |
| 2              | 3                     |
| 3              | 1                     |

1st runner has the most successful order, while runner 3 has the least.

4. How many of each type of pizza was delivered?

```sql
SELECT 
	pn.pizza_name, 
	COUNT(co.pizza_id) AS ordered
FROM 
	customer_orders AS co, 
    pizza_names as pn, 
    runner_orders AS ro
WHERE ro.pickup_time != 'null' 
	AND co.order_id = ro.order_id
	AND co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name;
```

| pizza_name      | ordered      |
| --------------- | ------------ |
| Meatlovers      | 9            |
| Vegetarian      | 3            |

From those 8 successul order from the query before, 12 pizza were ordered. Meatlovers pizza is more preferred than vegetarian.

5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT 
	co.customer_id, 
	pn.pizza_name, 
	COUNT(co.pizza_id) AS ordered
FROM 
	customer_orders AS co
JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, co.pizza_id
ORDER BY co.customer_id;
```

| customer_id      | pizza_name      | ordered      |
|--------------| --------------| -----------|
| 101              | Meatlovers      | 2            |
| 101              | Vegetarian      | 1            |
| 102              | Meatlovers      | 2            |
| 102              | Vegetarian      | 1            |
| 103              | Meatlovers      | 3            |
| 103              | Vegetarian      | 1            |
| 104              | Meatlovers      | 3            |
| 105              | Vegetarian      | 1            |

6. What was the maximum number of pizzas delivered in a single order?
   
```sql
SELECT 
	co.order_id,
    COUNT(co.order_id) AS max_pizza
FROM 
	customer_orders AS co, 
    runner_orders AS ro
WHERE ro.pickup_time != 'null' 
	AND co.order_id = ro.order_id
GROUP BY co.order_id
ORDER BY max_pizza DESC
LIMIT 1;
```

| order_id      | max_pizza      |
|-----------| -------------|
| 4             | 3              |

Maximum of 3 pizzas delivered in a single order, from order_id 4.

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT
	customer_id, 
	SUM(
		(CASE 
			WHEN IFNULL(exclusions, '') REGEXP '[1-9]' OR IFNULL(extras, '') REGEXP '[1-9]' 
			THEN 1 ELSE 0 END)
		) AS pizza_with_changes, 
	SUM(
		(CASE 
			WHEN IFNULL(exclusions, '') NOT REGEXP '[1-9]' AND IFNULL(extras, '') NOT REGEXP '[1-9]'
			THEN 1 ELSE 0 END)
		) AS pizza_no_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND ro.pickup_time != 'null'
GROUP BY co.customer_id;
```

| customer_id      | pizza_with_changes      | pizza_no_changes      |
| --------------|  ----------------------|  --------------------| 
| 101              | 0                       | 2                     |
| 102              | 0                       | 3                     |
| 103              | 3                       | 0                     |
| 104              | 2                       | 1                     |
| 105              | 1                       | 0                     |

The customers tend to order pizza either only with changes or no changes at all.

8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT
	SUM( 
		(CASE 
			WHEN IFNULL(exclusions, '') REGEXP '[1-9]' AND IFNULL(extras, '') REGEXP '[1-9]' 
			THEN 1 ELSE 0 END)
        ) AS delivered_pizza_with_both_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND ro.pickup_time != 'null';
```

| delivered_pizza_with_both_changes      |
 | ------------------------------------ | 
| 1                                      |

9.  What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT HOUR(order_time) AS hour, COUNT(HOUR(order_time)) AS pizza_ordered
FROM customer_orders
GROUP BY hour
ORDER BY hour;
```

| hour      | pizza_ordered      |
 | ------- |  ----------------- | 
| 11        | 1                  |
| 13        | 3                  |
| 18        | 3                  |
| 19        | 1                  |
| 21        | 3                  |
| 23        | 3                  |

Most orders were made at nightime (18-23).

10.  What was the volume of orders for each day of the week?

```sql
SELECT DAYNAME(order_time) AS day, COUNT(HOUR(order_time)) AS pizza_ordered
FROM customer_orders
GROUP BY day
ORDER BY DAYOFWEEK(order_time);
```

| day      | pizza_ordered      |
 | ------ |  ----------------- | 
| Wednesday | 5                  |
| Thursday | 3                  |
| Friday   | 1                  |
| Saturday | 5                  |

Most orders were made at Wednesday and Saturday.

## B. Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
SELECT week, COUNT(week) AS new_runners
FROM (SELECT WEEK(registration_date, 1)+1 AS week FROM runners) AS weeks
GROUP BY week;
```

| week      | new_runners      |
 | ------- |  --------------- | 
| 1         | 2                |
| 2         | 1                |
| 3         | 1                |

Each week, at least one new runner sign up.

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT 
	ro.runner_id,
	FORMAT(AVG(TIMESTAMPDIFF(MINUTE, 
		co.order_time, 
        STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s'))), 
        2) AS 'average_pickup_duration (minutes)'
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND ro.pickup_time != 'null'
GROUP BY ro.runner_id;
```

| runner_id      | average_pickup_duration (minutes)      |
 | ------------ |  ------------------------------------- | 
| 1              | 15.33                                  |
| 2              | 23.40                                  |
| 3              | 10.00                                  |

Average pickup duration is in range of 10-24 minutes.

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
SELECT
	pizza_ordered,
    FORMAT(AVG(preparation_time)/60, 2) AS 'average_preparation_time (minutes)'
FROM (
	SELECT
    COUNT(co.order_id) as pizza_ordered,
	TIMESTAMPDIFF(SECOND, 
		co.order_time, 
        STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s')) AS preparation_time
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND ro.pickup_time != 'null'
GROUP BY co.order_id
) AS prep
GROUP BY pizza_ordered;
```

| pizza_ordered      | average_preparation_time (minutes)      |
 | ---------------- |  -------------------------------------- | 
| 1                  | 12.36                                   |
| 2                  | 18.38                                   |
| 3                  | 29.28                                   |

There is a relationship between pizza ordered and average preparation time. More pizza ordered mean more preparation time, with 2 pizza ordered has the quickest preparation time for each pizza.

4. What was the average distance travelled for each customer?

```sql
SELECT co.customer_id, FORMAT(AVG(distance+0), 2) AS 'average distance (km)'
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance != 'null'
GROUP BY co.customer_id;
```

| customer_id      | average distance (km)      |
 | -------------- |  ------------------------- | 
| 101              | 20.00                      |
| 102              | 16.73                      |
| 103              | 23.40                      |
| 104              | 10.00                      |
| 105              | 25.00                      |

Average distance traveled is between 10-25 km.

5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration+0)-MIN(duration+0) AS 'duration difference (minutes)'
FROM runner_orders
WHERE distance != 'null';
```

| duration difference (minutes)      |
 | -------------------------------- | 
| 30                                 |

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT 
	ro.runner_id, 
    FORMAT(AVG(distance+0), 2) AS 'average distance (km)', 
    FORMAT(AVG(duration+0), 2) AS 'average duration (minutes)',
    FORMAT(AVG(distance+0)/AVG(duration+0)*60, 2) AS 'average speed (km/hour)'
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance != 'null'
GROUP BY ro.runner_id;
```

| runner_id      | average distance (km)      | average duration (minutes)      | average speed (km/hour)      |
 | ------------ |  ------------------------- |  ------------------------------ |  --------------------------- | 
| 1              | 14.47                      | 19.83                           | 43.76                        |
| 2              | 23.72                      | 32.00                           | 44.47                        |
| 3              | 10.00                      | 15.00                           | 40.00                        |

The average speed of the runners is roughly the same, around 44 km/hour. Runner 3 has only one delivery, with the shortest average distance and the slowest speed.

7. What is the successful delivery percentage for each runner?

```sql
SELECT 
	runner_id, 
	SUM(distance != 'null') AS success, 
    SUM(distance = 'null') AS failure,
    CONCAT(FORMAT(SUM(distance != 'null') / COUNT(distance)*100, 0), '%') AS success_percentage
FROM runner_orders
GROUP BY runner_id;
```

| runner_id      | success      | failure      | success_percentage      |
 | ------------ |  ----------- |  ----------- |  ---------------------- | 
| 1              | 4            | 0            | 100%                    |
| 2              | 3            | 1            | 75%                     |
| 3              | 1            | 1            | 50%                     |

## C. Ingredient Optimisation
1. What are the standard ingredients for each pizza?

```sql
WITH topping_separated AS (SELECT 
	pr.pizza_id,
    substring_index(
    substring_index(pr.toppings, ',', pt.topping_id), 
    ',', 
    -1
  )+0 as topping
FROM pizza_recipes AS pr
JOIN pizza_toppings AS pt
ON CHAR_LENGTH(pr.toppings) - CHAR_LENGTH(REPLACE(pr.toppings, ',', '')) >= pt.topping_id-1
ORDER BY pizza_id)

SELECT 
	ts.pizza_id, 
    GROUP_CONCAT(pt.topping_name SEPARATOR ', ') as ingredients
FROM topping_separated AS ts
JOIN pizza_toppings AS pt
	ON ts.topping = pt.topping_id
GROUP BY pizza_id;
```

| pizza_id      | ingredients      |
 | ----------- |  ------------ | 
| 1             | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2             | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

2. What was the most commonly added extra?

```sql
WITH extras AS (SELECT 
	co.order_id,
    substring_index(
    substring_index(co.extras, ',', pt.topping_id), 
    ',', 
    -1
  )+0 as topping
FROM customer_orders AS co
JOIN pizza_toppings AS pt
ON CHAR_LENGTH(co.extras) - CHAR_LENGTH(REPLACE(co.extras, ',', '')) >= pt.topping_id-1)

SELECT topping_id, topping_name, COUNT(topping) AS ordered
FROM extras 
JOIN pizza_toppings
ON topping_id = topping
GROUP BY topping;
```

| topping_id      | topping_name      | ordered      |
 | ------------- |  ---------------- |  ----------- | 
| 1               | Bacon             | 4            |
| 5               | Chicken           | 1            |
| 4               | Cheese            | 1            |

Bacon is the favorite topping.

3. What was the most common exclusion?

```sql
WITH exclusions AS (SELECT 
	co.order_id,
    substring_index(
    substring_index(co.exclusions, ',', pt.topping_id), 
    ',', 
    -1
  )+0 as exclusion
FROM customer_orders AS co
JOIN pizza_toppings AS pt
ON CHAR_LENGTH(co.exclusions) - CHAR_LENGTH(REPLACE(co.exclusions, ',', '')) >= pt.topping_id-1)

SELECT topping_id, topping_name, COUNT(exclusion) AS excluded
FROM exclusions 
JOIN pizza_toppings
ON topping_id = exclusion
GROUP BY exclusion;
```

| topping_id      | topping_name      | excluded      |
 | ------------- |  ---------------- |  ------------ | 
| 4               | Cheese            | 4             |
| 6               | Mushrooms         | 1             |
| 2               | BBQ Sauce         | 1             |

Cheese is the most excluded topping.

4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
   - `Meat Lovers`
   - `Meat Lovers - Exclude Beef`
   - `Meat Lovers - Extra Bacon`
   - `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`

```sql
WITH modifier AS (SELECT 
	co.pizza_order_id,
	co.order_id,
    co.pizza_id,
    substring_index(
		substring_index(co.extras, ',', pt.topping_id), 
		',', 
		-1
		)+0 AS topping,
    substring_index(
		substring_index(co.exclusions, ',', pt.topping_id), 
		',', 
		-1
		)+0 AS exclusion
FROM 
	(SELECT 
		*, 
		ROW_NUMBER() OVER w AS 'pizza_order_id' 
	FROM customer_orders
	WINDOW w AS (ORDER BY order_id)
	) AS co
LEFT JOIN pizza_toppings AS pt
	ON CHAR_LENGTH(co.extras) - CHAR_LENGTH(REPLACE(co.extras, ',', '')) >= pt.topping_id-1
)

SELECT 
	order_id, 
    (CASE 
		WHEN exclusion IS NOT NULL
		THEN CASE
			WHEN topping IS NOT NULL
			THEN CONCAT_WS('', pizza_name, ' - Exclude ', CONCAT_WS(', ', exclusion), ' - Extras ', CONCAT_WS(', ', topping))
			ELSE CONCAT_WS('', pizza_name, ' - Exclude ', CONCAT_WS(', ', exclusion)) END
		ELSE pizza_name END
    ) AS order_name
FROM (
	SELECT m.pizza_order_id, m.order_id, pn.pizza_name, 
		GROUP_CONCAT(DISTINCT (CASE WHEN m.topping = topping_id THEN topping_name ELSE null END) SEPARATOR ', ') as topping, 
		GROUP_CONCAT(DISTINCT (CASE WHEN m.exclusion = topping_id THEN topping_name ELSE null END) SEPARATOR ', ') as exclusion 
	FROM modifier AS m
	LEFT JOIN pizza_toppings
		ON topping_id = topping OR topping_id = exclusion
	JOIN pizza_names AS pn
		ON m.pizza_id = pn.pizza_id
	GROUP BY pizza_order_id) AS order_name;
SELECT * FROM customer_orders;
```

| order_id      | order_name      |
 | ----------- |  -------------- | 
| 1             | Meatlovers      |
| 2             | Meatlovers      |
| 3             | Meatlovers      |
| 3             | Vegetarian      |
| 4             | Meatlovers - Exclude Cheese |
| 4             | Meatlovers - Exclude Cheese |
| 4             | Vegetarian - Exclude Cheese |
| 5             | Meatlovers      |
| 6             | Vegetarian      |
| 7             | Vegetarian      |
| 8             | Meatlovers      |
| 9             | Meatlovers - Exclude Cheese - Extras Bacon, Chicken |
| 10            | Meatlovers      |
| 10            | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extras Bacon, Cheese |

5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the `customer_orders` table and add a 2x in front of any relevant ingredients
    - For example: `"Meat Lovers: 2xBacon, Beef, ... , Salami"`

```sql
WITH modifier AS (SELECT 
	co.pizza_order_id,
	co.order_id,
    IF(co.exclusions REGEXP '[0-9]', co.exclusions, null) AS exclusions,
    IF(co.extras REGEXP '[0-9]', co.extras, null) AS extras,
    recipe
FROM 
	(SELECT 
		customer_orders.*, 
        pizza_recipes.toppings AS recipe,
		ROW_NUMBER() OVER w AS 'pizza_order_id' 
	FROM customer_orders
    JOIN pizza_recipes
		ON customer_orders.pizza_id = pizza_recipes.pizza_id
	WINDOW w AS (ORDER BY order_id)
	) AS co
)

SELECT pizza_order_id, order_id,
	GROUP_CONCAT(CASE 
		WHEN count_topping=2
        THEN CONCAT_WS('','2x',topping_name)
        ELSE topping_name
	END SEPARATOR ', ') AS topping_name
FROM
(
	SELECT pizza_order_id, order_id, topping_name, COUNT(topping) AS count_topping
	FROM
	(
		SELECT
			tmp.pizza_order_id,
			tmp.order_id,
			substring_index(
				substring_index(all_toppings, ',', m.pizza_order_id), 
				',', 
				-1
				)+0 AS topping
		FROM (
			SELECT pizza_order_id, order_id,
				CONCAT_WS(', ',
						REPLACE(
							REPLACE(recipe, 
							CONCAT_WS(', ', SUBSTRING_INDEX(exclusions, ',', 1), ''), ''), 
							CONCAT_WS(', ', SUBSTRING_INDEX(exclusions, ',', 2), ''), ''),
						extras) AS all_toppings
			FROM modifier
		) AS tmp
		JOIN modifier AS m
		ON CHAR_LENGTH(all_toppings) - CHAR_LENGTH(REPLACE(all_toppings, ',', '')) >= m.pizza_order_id-1
		ORDER BY tmp.pizza_order_id
	) AS tmp
    JOIN pizza_toppings
		ON topping = pizza_toppings.topping_id
	GROUP BY pizza_order_id, topping
	ORDER BY pizza_order_id
) AS tmp
GROUP BY pizza_order_id;
```

| pizza_order_id      | order_id      | topping_name      |
 | ----------------- |  ------------ |  ---------------- | 
| 1                   | 1             | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2                   | 2             | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3                   | 3             | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 4                   | 3             | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 5                   | 4             | Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 6                   | 4             | Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 7                   | 4             | Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 8                   | 5             | 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9                   | 6             | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 10                  | 7             | Bacon, Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 11                  | 8             | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 12                  | 9             | 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami |
| 13                  | 10            | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 14                  | 10            | 2xBacon, Beef, 2xCheese, Chicken, Mushrooms, Pepperoni, Salami |

6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

```sql
WITH modifier AS (SELECT 
	co.pizza_order_id,
	co.order_id,
    IF(co.exclusions REGEXP '[0-9]', co.exclusions, null) AS exclusions,
    IF(co.extras REGEXP '[0-9]', co.extras, null) AS extras,
    recipe
FROM 
	(SELECT 
		customer_orders.*, 
        pizza_recipes.toppings AS recipe,
		ROW_NUMBER() OVER w AS 'pizza_order_id' 
	FROM customer_orders
    JOIN pizza_recipes
		ON customer_orders.pizza_id = pizza_recipes.pizza_id
	WINDOW w AS (ORDER BY order_id)
	) AS co
)

SELECT topping_name, COUNT(topping) AS count_topping
FROM
(
	SELECT
		tmp.pizza_order_id,
		tmp.order_id,
		substring_index(
			substring_index(all_toppings, ',', m.pizza_order_id), 
			',', 
			-1
			)+0 AS topping
	FROM (
		SELECT pizza_order_id, order_id,
			CONCAT_WS(', ',
					REPLACE(
						REPLACE(recipe, 
						CONCAT_WS(', ', SUBSTRING_INDEX(exclusions, ',', 1), ''), ''), 
						CONCAT_WS(', ', SUBSTRING_INDEX(exclusions, ',', 2), ''), ''),
					extras) AS all_toppings
		FROM modifier
	) AS tmp
	JOIN modifier AS m
	ON CHAR_LENGTH(all_toppings) - CHAR_LENGTH(REPLACE(all_toppings, ',', '')) >= m.pizza_order_id-1
	ORDER BY tmp.pizza_order_id
) AS tmp
JOIN pizza_toppings
	ON topping = pizza_toppings.topping_id
GROUP BY topping
ORDER BY count_topping DESC;
```

| topping_name      | count_topping      |
 | --------------- |  ----------------- | 
| Bacon             | 14                 |
| Mushrooms         | 14                 |
| Cheese            | 11                 |
| Chicken           | 11                 |
| Beef              | 10                 |
| Pepperoni         | 10                 |
| Salami            | 10                 |
| BBQ Sauce         | 9                  |
| Onions            | 4                  |
| Peppers           | 4                  |
| Tomatoes          | 4                  |
| Tomato Sauce      | 4                  |

## D. Pricing and Ratings
1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```sql
SELECT SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) as 'total_profit ($)' FROM customer_orders;
```

| total_profit ($)      |
 | ------------------- | 
| 160                   |




2. What if there was an additional $1 charge for any pizza extras?
   - Add cheese is $1 extra

```sql
SELECT 
	SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) +
    SUM(CASE 
			WHEN extras REGEXP '[,]' THEN 2
            WHEN extras REGEXP '[0-9]' THEN 1
            ELSE 0 END) AS 'total_profit ($)'
FROM customer_orders;
```

| total_profit ($)      |
 | ------------------- | 
| 166                   |

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  `order_id` INTEGER,
  `runner_id` INTEGER,
  `rating` INTEGER
);
INSERT INTO runner_ratings
  (`order_id`, `runner_id`, `rating`)
VALUES
  ('1', '1', '3'),
  ('2', '1', '2'),
  ('3', '1', '5'),
  ('4', '2', '3'),
  ('5', '3', '2'),
  ('6', '3', '1'),
  ('7', '2', '5'),
  ('8', '2', '3'),
  ('9', '2', '4'),
  ('10', '1', '2');

SELECT * FROM runner_ratings;
```

| order_id      | runner_id      | rating      |
 | ----------- |  ------------- |  ---------- | 
| 1             | 1              | 3           |
| 2             | 1              | 2           |
| 3             | 1              | 5           |
| 4             | 2              | 3           |
| 5             | 3              | 2           |
| 6             | 3              | 1           |
| 7             | 2              | 5           |
| 8             | 2              | 3           |
| 9             | 2              | 4           |
| 10            | 1              | 2           |

4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
   - `customer_id`
   - `order_id`
   - `runner_id`
   - `rating`
   - `order_time`
   - `pickup_time`
   - Time between order and pickup
   - Delivery duration
   - Average speed
   - Total number of pizzas

```sql
SELECT 
	co.customer_id, 
    co.order_id, 
    ro.runner_id, 
    rr.rating, 
    co.order_time, 
    ro.pickup_time,
	FORMAT(TIMESTAMPDIFF(MINUTE, 
		co.order_time, 
		STR_TO_DATE(ro.pickup_time, '%Y-%m-%d %H:%i:%s')), 
		0) AS 'pickup_duration (minutes)',
	FORMAT(duration+0, 0) AS 'delivery_duration (minutes)',
    FORMAT((distance+0)/(duration+0)*60, 2) AS 'average_speed (km/hour)',
    COUNT(co.order_id) as total_pizza
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND pickup_time!='null'
JOIN runner_ratings as rr
	ON co.order_id = rr.order_id
GROUP BY order_id;
```

| customer_id      | order_id      | runner_id      | rating      | order_time      | pickup_time      | pickup_duration (minutes)      | delivery_duration (minutes)      | average_speed (km/hour)      | total_pizza      |
 | -------------- |  ------------ |  ------------- |  ---------- |  -------------- |  --------------- |  ----------------------------- |  ------------------------------- |  --------------------------- |  --------------- | 
| 101              | 1             | 1              | 3           | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10                             | 32                               | 37.50                        | 1                |
| 101              | 2             | 1              | 2           | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10                             | 27                               | 44.44                        | 1                |
| 102              | 3             | 1              | 5           | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21                             | 20                               | 40.20                        | 2                |
| 103              | 4             | 2              | 3           | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29                             | 40                               | 35.10                        | 3                |
| 104              | 5             | 3              | 2           | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10                             | 15                               | 40.00                        | 1                |
| 105              | 7             | 2              | 5           | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10                             | 25                               | 60.00                        | 1                |
| 102              | 8             | 2              | 3           | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20                             | 15                               | 93.60                        | 1                |
| 104              | 10            | 1              | 2           | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15                             | 10                               | 60.00                        | 2                |

5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```sql
SELECT SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END)-SUM(distance+0)*0.3 as 'total_profit ($)' 
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id;
```

| total_profit ($)      |
 | ------------------- | 
| 95.38                 |