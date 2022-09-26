-- Author: Elbert Timothy Lasiman

#################################

-- A. Data Exploration and Cleansing

-- Q1: Update the fresh_segments.interest_metrics table by modifying the month_year column to be 
-- a date data type with the start of the month
ALTER TABLE interest_metrics ADD month_year2 DATE AFTER month_year; 
UPDATE interest_metrics
SET month_year2 = STR_TO_DATE(month_year, '%m-%Y');
ALTER TABLE interest_metrics DROP month_year;
ALTER TABLE interest_metrics RENAME COLUMN month_year2 to month_year;
SELECT * FROM interest_metrics;

-- Q2: What is count of records in the fresh_segments.interest_metrics for each month_year value 
-- sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year, COUNT(*) as count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;

-- Q3: What do you think we should do with these null values in the fresh_segments.interest_metrics
SELECT * FROM interest_metrics WHERE month_year IS NULL LIMIT 5;
SELECT CONCAT(FORMAT(COUNT(*)/total_data*100,2),'%') as null_percentage
FROM interest_metrics
JOIN (SELECT COUNT(*) as total_data FROM interest_metrics) as total
WHERE month_year IS NULL;

DELETE FROM interest_metrics WHERE month_year IS NULL;

-- Q4: How many interest_id values exist in the fresh_segments.interest_metrics table 
-- but not in the fresh_segments.interest_map table? What about the other way around?
SELECT 'metrics not in map' as interest, COUNT(*) as count
FROM interest_metrics as i
LEFT JOIN interest_map as map 
	ON i.interest_id = map.id
WHERE i.interest_id IS NULL
UNION ALL
SELECT 'as map not in metrics', COUNT(*)
FROM interest_metrics as i
RIGHT JOIN interest_map as map
	ON i.interest_id = map.id
WHERE i.interest_id IS NULL;

-- Q5: Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT COUNT(*) as id_count FROM interest_map;

-- Q6: What sort of table join should we perform for our analysis and why? 
-- Check your logic by checking the rows where interest_id = 21246 in your joined output 
-- and include all columns from fresh_segments.interest_metrics and all columns 
-- from fresh_segments.interest_map except from the id column.
SELECT i.*, interest_name, interest_summary, created_at, last_modified
FROM interest_metrics as i
JOIN interest_map as map
	ON i.interest_id = map.id
WHERE i.interest_id=21246;

-- Q7: Are there any records in your joined table where the month_year value is before the created_at value 
-- from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT i.*, interest_name, interest_summary, created_at, last_modified
FROM interest_metrics as i
JOIN interest_map as map
	ON i.interest_id = map.id
WHERE month_year<created_at
LIMIT 5;

-- it's valid. month_year column does not include day after all.

#################################

-- B. Interest Analysis

-- Q1: Which interests have been present in all month_year dates in our dataset?
SELECT 
	interest_id,
	SUM(COUNT(DISTINCT month_year) = total_months) OVER() as total_interests
FROM interest_metrics
JOIN (SELECT COUNT(DISTINCT month_year) as total_months FROM interest_metrics) as total_months
GROUP BY interest_id
LIMIT 5;


-- Q2: Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - 
-- which total_months value passes the 90% cumulative percentage value?
SELECT 
	total_months, 
	COUNT(interest_id) as total_interest, 
	CONCAT(FORMAT(SUM(COUNT(interest_id)) OVER(ORDER BY total_months DESC)/SUM(COUNT(interest_id)) OVER()*100, 2), '%') as cumulative_percentage
FROM 
	(SELECT interest_id, COUNT(DISTINCT(month_year)) as total_months 
	FROM interest_metrics 
	GROUP BY interest_id) as t
GROUP BY total_months
ORDER BY total_months DESC;

-- Q3: If we were to remove all interest_id values which are lower than the total_months value 
-- we found in the previous question - how many total data points would we be removing?
SELECT COUNT(*) as data_count
FROM
	(SELECT 
		*,
		COUNT(month_year) OVER(PARTITION BY interest_id) as total_months 
	FROM interest_metrics) as t
WHERE total_months<=6;

-- Q4: Does this decision make sense to remove these data points from a business perspective? 
-- Use an example where there are all 14 months present to a removed interest example for your arguments - 
-- think about what it means to have less months present from a segment perspective.
SELECT t.*, m.interest_name, m.interest_summary
FROM
	(SELECT 
		*,
		COUNT(month_year) OVER(PARTITION BY interest_id) as total_months 
	FROM interest_metrics) as t
JOIN interest_map as m
	ON m.id = t.interest_id
WHERE interest_id = 48154;

-- Q5: After removing these interests - how many unique interests are there for each month?
DROP TABLE IF EXISTS interest_metrics_filtered;
CREATE TABLE interest_metrics_filtered AS
(SELECT _month, _year, month_year, interest_id, composition, index_value, ranking, percentile_ranking
FROM
	(SELECT 
		*,
		COUNT(month_year) OVER(PARTITION BY interest_id) as total_months 
	FROM interest_metrics) as t
WHERE total_months>6);

SELECT i1.month_year, COUNT(DISTINCT i1.interest_id) as total_interest_after, total_interest_before
FROM interest_metrics_filtered as i1
JOIN 
	(SELECT month_year, COUNT(DISTINCT interest_id) as total_interest_before 
    FROM interest_metrics 
    GROUP BY month_year) as i2
	ON i1.month_year = i2.month_year
GROUP BY i1.month_year;

#################################

-- C. Segment Analysis

-- Q1: Using our filtered dataset by removing the interests with less than 6 months worth of data, 
-- which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
-- Only use the maximum composition value for each interest but you must keep the corresponding month_year
(SELECT 
	month_year,
    i.interest_id,
    interest_name,
    max_composition as max_or_min_composition,
    'top 10' as ranking
FROM interest_metrics_filtered as i
JOIN 
	(SELECT interest_id, max(composition) as max_composition 
	FROM interest_metrics_filtered
    GROUP BY interest_id ORDER BY max_composition DESC LIMIT 10) as t
	ON max_composition = composition AND i.interest_id=t.interest_id
JOIN interest_map as map
	ON i.interest_id = map.id
GROUP BY interest_id
ORDER BY composition DESC
LIMIT 10)
UNION
(SELECT 
	month_year,
    i.interest_id,
    interest_name,
    composition,
    'bottom 10' as ranking
FROM interest_metrics_filtered as i
JOIN 
	(SELECT interest_id, min(composition) as min_composition 
	FROM interest_metrics_filtered
    GROUP BY interest_id ORDER BY min_composition LIMIT 10) as t
	ON min_composition = composition AND i.interest_id=t.interest_id
JOIN interest_map as map
	ON i.interest_id = map.id
GROUP BY interest_id
ORDER BY composition LIMIT 10);

-- Q2: Which 5 interests had the lowest average ranking value?
SELECT 
    interest_id,
    interest_name,
    FORMAT(AVG(composition),2) as composition
FROM interest_metrics_filtered as i
JOIN interest_map as map
	ON i.interest_id = map.id
GROUP BY interest_id
ORDER BY composition 
LIMIT 5;

-- Q3: Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT 
    interest_id,
    interest_name,
    FORMAT(STDDEV_SAMP(percentile_ranking),2) as stdev_composition
FROM interest_metrics_filtered as i
JOIN interest_map as map
	ON i.interest_id = map.id
GROUP BY interest_id
ORDER BY composition DESC
LIMIT 5;

-- Q4: For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values 
-- for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
WITH t as
(SELECT 
		interest_id,
		FORMAT(STDDEV_SAMP(percentile_ranking),2) as stdev_composition
	FROM interest_metrics_filtered as i
	GROUP BY interest_id
	ORDER BY composition DESC
	LIMIT 5)

SELECT DISTINCT i.interest_id, interest_name, min_composition, min_month_year, max_composition, max_month_year, stdev_composition
FROM interest_metrics_filtered as i
JOIN
	(SELECT month_year as min_month_year, i.interest_id, min_composition, stdev_composition
	FROM interest_metrics_filtered as i
	JOIN
		(SELECT i.interest_id, min(composition) as min_composition, stdev_composition 
		FROM interest_metrics_filtered as i
		JOIN t 
			ON i.interest_id = t.interest_id
		GROUP BY interest_id) as min
		ON min.interest_id = i.interest_id AND min_composition = i.composition) as min_month
	ON min_month.interest_id = i.interest_id
JOIN
	(SELECT month_year as max_month_year, i.interest_id, max_composition
	FROM interest_metrics_filtered as i
	JOIN
		(SELECT i.interest_id, max(composition) as max_composition 
		FROM interest_metrics_filtered as i
		JOIN t 
			ON i.interest_id = t.interest_id
		GROUP BY interest_id) as max
		ON max.interest_id = i.interest_id AND max_composition = i.composition) as max_month
	ON max_month.interest_id = i.interest_id
JOIN interest_map as map
	ON i.interest_id = map.id;

-- Q5: How would you describe our customers in this segment based off their composition and ranking values? 
-- What sort of products or services should we show to these customers and what should we avoid?
-- use query on question 1

SELECT * FROM interest_metrics_filtered as i
JOIN interest_map as map
	ON i.interest_id = map.id
ORDER BY ranking DESC;

#################################

-- D. Index Analysis

-- Q1: What is the top 10 interests by the average composition for each month?
SELECT month_year, interest_id, interest_name, composition, index_value, avg_composition, avg_comp_rank
FROM
	(SELECT 
	*, 
	FORMAT(composition/index_value, 2) as avg_composition,
	RANK() OVER(PARTITION BY month_year ORDER BY composition/index_value DESC) avg_comp_rank
	FROM interest_metrics_filtered) as t
JOIN interest_map as map
	ON t.interest_id = map.id
WHERE avg_comp_rank<=10
ORDER BY month_year;

-- Q2: For all of these top 10 interests - which interest appears the most often?
SELECT interest_id, interest_name, COUNT(interest_id) as total_appear
FROM
	(SELECT 
	*, 
	FORMAT(composition/index_value, 2) as avg_composition,
	RANK() OVER(PARTITION BY month_year ORDER BY composition/index_value DESC) avg_comp_rank
	FROM interest_metrics_filtered) as t
JOIN interest_map as map
	ON t.interest_id = map.id
WHERE avg_comp_rank<=10
GROUP BY interest_id
ORDER BY total_appear DESC
LIMIT 5;

-- Q3: What is the average of the average composition for the top 10 interests for each month?
SELECT month_year, FORMAT(AVG(avg_composition), 2) as avg_of_avg_comp
FROM
	(SELECT 
	*, 
	FORMAT(composition/index_value, 2) as avg_composition,
	RANK() OVER(PARTITION BY month_year ORDER BY composition/index_value DESC) avg_comp_rank
	FROM interest_metrics_filtered) as t
JOIN interest_map as map
	ON t.interest_id = map.id
WHERE avg_comp_rank<=10
GROUP BY month_year;

-- Q4: What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 
-- and include the previous top ranking interests in the same output shown below.
SELECT *
FROM 
	(SELECT 
		month_year, interest_name, max_avg_composition, 3_month_moving_avg,
		CONCAT_WS(': ', LAG(interest_name) OVER(ORDER BY month_year),
			 LAG(max_avg_composition) OVER(ORDER BY month_year)) as 1_month_ago,
		CONCAT_WS(': ', NTH_VALUE(interest_name, 1) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
			NTH_VALUE(max_avg_composition, 1) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) as 2_months_ago
	FROM
		(SELECT 
		*, 
		FORMAT(composition/index_value, 2) as max_avg_composition,
		RANK() OVER(PARTITION BY month_year ORDER BY composition/index_value DESC) avg_comp_rank,
		(CASE 
			WHEN ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY month_year) >= 3
			THEN FORMAT(AVG(composition/index_value) OVER(PARTITION BY interest_id 
				ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)
			ELSE NULL
		END) as 3_month_moving_avg
		FROM interest_metrics_filtered) as t
	JOIN interest_map as map
		ON t.interest_id = map.id
	WHERE avg_comp_rank=1
	ORDER BY month_year) as t
WHERE month_year>='2018-09-00';

-- Q5: Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

#################################