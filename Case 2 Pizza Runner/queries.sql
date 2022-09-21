-- Author: Elbert Timothy Lasiman

-- --------------------------------------

-- A. Pizza Metrics

-- Q1: How many pizzas were ordered?
SELECT COUNT(pizza_id) AS ordered_pizza FROM customer_orders;

-- Q2: How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_orders FROM customer_orders;

-- Q3: How many successful orders were delivered by each runner?
SELECT 
	runner_id, 
	COUNT(order_id) AS successful_order
FROM runner_orders
WHERE pickup_time != 'null'
GROUP BY runner_id;

-- Q4: How many of each type of pizza was delivered?
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

-- Q5: How many Vegetarian and Meatlovers were ordered by each customer?
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

-- Q6: What was the maximum number of pizzas delivered in a single order?
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

-- Q7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
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

-- Q8: How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM( 
		(CASE 
			WHEN IFNULL(exclusions, '') REGEXP '[1-9]' AND IFNULL(extras, '') REGEXP '[1-9]' 
			THEN 1 ELSE 0 END)
        ) AS delivered_pizza_with_both_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id AND ro.pickup_time != 'null';

-- Q9: What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time) AS hour, COUNT(HOUR(order_time)) AS pizza_ordered
FROM customer_orders
GROUP BY hour
ORDER BY hour;

-- Q10: What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS day, COUNT(HOUR(order_time)) AS pizza_ordered
FROM customer_orders
GROUP BY day
ORDER BY DAYOFWEEK(order_time);

-- --------------------------------------

-- B. Runner and Customer Experience

-- Q1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT week, COUNT(week) AS new_runners
FROM (SELECT WEEK(registration_date, 1)+1 AS week FROM runners) AS weeks
GROUP BY week;

-- Q2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
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

-- Q3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
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

-- Q4: What was the average distance travelled for each customer?
SELECT co.customer_id, FORMAT(AVG(distance+0), 2) AS 'average distance (km)'
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE distance != 'null'
GROUP BY co.customer_id;

-- Q5: What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration+0)-MIN(duration+0) AS 'duration difference (minutes)'
FROM runner_orders
WHERE distance != 'null';

-- Q6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
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

-- Q7: What is the successful delivery percentage for each runner?
SELECT 
	runner_id, 
	SUM(distance != 'null') AS success, 
    SUM(distance = 'null') AS failure,
    CONCAT(FORMAT(SUM(distance != 'null') / COUNT(distance)*100, 0), '%') AS success_percentage
FROM runner_orders
GROUP BY runner_id;

-- --------------------------------------

-- C. Ingredient Optimisation

-- Q1: What are the standard ingredients for each pizza?
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

-- Q2: What was the most commonly added extra?
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

-- Q3: What was the most common exclusion?
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

-- Q4: Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
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

-- Q5: Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
-- and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

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

-- Q6: What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
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

-- --------------------------------------

-- D. Pricing and Ratings

-- Q1: If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
-- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) as 'total_profit ($)' FROM customer_orders;

-- Q2: What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
SELECT 
	SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) +
    SUM(CASE 
			WHEN extras REGEXP '[,]' THEN 2
            WHEN extras REGEXP '[0-9]' THEN 1
            ELSE 0 END) AS 'total_profit ($)'
FROM customer_orders;

-- Q3: The Pizza Runner team now wants to add an additional ratings system that allows customers 
-- to rate their runner, how would you design an additional table for this new dataset - 
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
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
  
-- Q4: Using your newly generated table - can you join all of the information together to 
-- form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

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

-- Q5: If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END)-SUM(distance+0)*0.3 as 'total_profit ($)' 
FROM customer_orders AS co
JOIN runner_orders AS ro
	ON co.order_id = ro.order_id;