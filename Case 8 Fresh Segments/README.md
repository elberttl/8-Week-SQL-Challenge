# Case Study #8 - Fresh Segments

- [Case Study #8 - Fresh Segments](#case-study-8---fresh-segments)
  - [A. Data Exploration and Cleansing](#a-data-exploration-and-cleansing)
  - [B. Interest Analysis](#b-interest-analysis)
  - [C. Segment Analysis](#c-segment-analysis)
  - [D. Index Analysis](#d-index-analysis)

## A. Data Exploration and Cleansing

1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
```sql
ALTER TABLE interest_metrics ADD month_year2 DATE AFTER month_year; 
UPDATE interest_metrics
SET month_year2 = STR_TO_DATE(month_year, '%m-%Y');
ALTER TABLE interest_metrics DROP month_year;
ALTER TABLE interest_metrics RENAME COLUMN month_year2 to month_year;
SELECT * FROM interest_metrics;
```

2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT month_year, COUNT(*) as count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
```
| month_year      | count      |
 |  ------------- |   --------- |  
|                 | 1194       |
| 2018-07-00      | 729        |
| 2018-08-00      | 767        |
| 2018-09-00      | 780        |
| 2018-10-00      | 857        |
| 2018-11-00      | 928        |
| 2018-12-00      | 995        |
| 2019-01-00      | 973        |
| 2019-02-00      | 1121       |
| 2019-03-00      | 1136       |
| 2019-04-00      | 1099       |
| 2019-05-00      | 857        |
| 2019-06-00      | 824        |
| 2019-07-00      | 864        |
| 2019-08-00      | 1149       |

Null value will be displayed first in MySQL with ascending order by.

3. What do you think we should do with these null values in the fresh_segments.interest_metrics
Let's see the null value first
```sql
SELECT * FROM interest_metrics WHERE month_year IS NULL LIMIT 5;
```
| _month      | _year      | month_year      | interest_id      | composition      | index_value      | ranking      | percentile_ranking      |
 |  --------- |   --------- |   -------------- |   --------------- |   --------------- |   --------------- |   ----------- |   ---------------------- |  
|             |            |                 |                  | 6.12             | 2.85             | 43           | 96.4                    |
|             |            |                 |                  | 7.13             | 2.84             | 45           | 96.23                   |
|             |            |                 |                  | 6.82             | 2.84             | 45           | 96.23                   |
|             |            |                 |                  | 5.96             | 2.83             | 47           | 96.06                   |
|             |            |                 |                  | 7.73             | 2.82             | 48           | 95.98                   |

```sql
SELECT CONCAT(FORMAT(COUNT(*)/total_data*100,2),'%') as null_percentage
FROM interest_metrics
JOIN (SELECT COUNT(*) as total_data FROM interest_metrics) as total
WHERE month_year IS NULL;
```
| null_percentage      |
 |  ------------------ |  
| 8.37%                |

Without knowing the interest_id and date, these data is meaningless. We won't know what the customer is interested even the composition is high. As the null value will not provide any insight and only 8% of the data, we will remove those.
```sql
DELETE FROM interest_metrics WHERE month_year IS NULL;
```


4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
```sql
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
```
| interest      | count      |
 |  ----------- |   --------- |  
| metrics not in map | 0          |
| as map not in metrics | 7          |

All interest in `interest_metrics` are also in `interest_map`. There are 7 interests in `interest_map` that are not in `interest_metrics`


5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
```sql
SELECT COUNT(*) as id_count FROM interest_map;
```
| id_count      |
 |  ----------- |  
| 1209          |

6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
```sql
SELECT i.*, interest_name, interest_summary, created_at, last_modified
FROM interest_metrics as i
JOIN interest_map as map
	ON i.interest_id = map.id
WHERE i.interest_id=21246;
```

| _month      | _year      | month_year      | interest_id      | composition      | index_value      | ranking      | percentile_ranking      | interest_name      | interest_summary      | created_at      | last_modified      |
 |  --------- |   --------- |   -------------- |   --------------- |   --------------- |   --------------- |   ----------- |   ---------------------- |   ----------------- |   -------------------- |   -------------- |   ----------------- |  
| 7           | 2018       | 2018-07-00      | 21246            | 2.26             | 0.65             | 722          | 0.96                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 8           | 2018       | 2018-08-00      | 21246            | 2.13             | 0.59             | 765          | 0.26                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 9           | 2018       | 2018-09-00      | 21246            | 2.06             | 0.61             | 774          | 0.77                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 10          | 2018       | 2018-10-00      | 21246            | 1.74             | 0.58             | 855          | 0.23                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 11          | 2018       | 2018-11-00      | 21246            | 2.25             | 0.78             | 908          | 2.16                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 12          | 2018       | 2018-12-00      | 21246            | 1.97             | 0.7              | 983          | 1.21                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 1           | 2019       | 2019-01-00      | 21246            | 2.05             | 0.76             | 954          | 1.95                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 2           | 2019       | 2019-02-00      | 21246            | 1.84             | 0.68             | 1109         | 1.07                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 3           | 2019       | 2019-03-00      | 21246            | 1.75             | 0.67             | 1123         | 1.14                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 4           | 2019       | 2019-04-00      | 21246            | 1.58             | 0.63             | 1092         | 0.64                    | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
We will perform inner join (or just `JOIN` in MySQL), as the `interest_map` table provide additional information of the `interest_id` from `interest_metrics` table.

7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
```sql
SELECT i.*, interest_name, interest_summary, created_at, last_modified
FROM interest_metrics as i
JOIN interest_map as map
	ON i.interest_id = map.id
WHERE month_year<created_at
LIMIT 5;
```

| _month      | _year      | month_year      | interest_id      | composition      | index_value      | ranking      | percentile_ranking      | interest_name      | interest_summary      | created_at      | last_modified      |
 |  --------- |   --------- |   -------------- |   --------------- |   --------------- |   --------------- |   ----------- |   ---------------------- |   ----------------- |   -------------------- |   -------------- |   ----------------- |  
| 7           | 2018       | 2018-07-00      | 32704            | 8.04             | 2.27             | 225          | 69.14                   | Major Airline Customers | People visiting sites for major airline brands to plan and view travel itinerary. | 2018-07-06 14:35:04 | 2018-07-06 14:35:04 |
| 7           | 2018       | 2018-07-00      | 33191            | 3.99             | 2.11             | 283          | 61.18                   | Online Shoppers    | People who spend money online | 2018-07-17 10:40:03 | 2018-07-17 10:46:58 |
| 7           | 2018       | 2018-07-00      | 32703            | 5.53             | 1.8              | 375          | 48.56                   | School Supply Shoppers | Consumers shopping for classroom supplies for K-12 students. | 2018-07-06 14:35:04 | 2018-07-06 14:35:04 |
| 7           | 2018       | 2018-07-00      | 32701            | 4.23             | 1.41             | 483          | 33.74                   | Womens Equality Advocates | People visiting sites advocating for womens equal rights. | 2018-07-06 14:35:03 | 2018-07-06 14:35:03 |
| 7           | 2018       | 2018-07-00      | 32705            | 4.38             | 1.34             | 505          | 30.73                   | Certified Events Professionals | Professionals reading industry news and researching products and services for event management. | 2018-07-06 14:35:04 | 2018-07-06 14:35:04 |

Some `month_year` date is before than the `created_at` date. But as we can see from the table above, these values are still in the same month. The `month_year` column does not specify the day which customer access the interests. So, these values are valid.

## B. Interest Analysis

1. Which interests have been present in all month_year dates in our dataset?
```sql
SELECT 
	interest_id,
	SUM(COUNT(DISTINCT month_year) = total_months) OVER() as total_interests
FROM interest_metrics
JOIN (SELECT COUNT(DISTINCT month_year) as total_months FROM interest_metrics) as total_months
GROUP BY interest_id
LIMIT 5;
```
| interest_id      | total_interests      |
 |  -------------- |   ------------------- |  
| 1                | 480                  |
| 100              | 480                  |
| 10007            | 480                  |
| 10008            | 480                  |
| 10009            | 480                  |

There are 480 interests that are present in all months.

2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
```sql
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
```
| total_months      | total_interest      | cumulative_percentage      |
 |  --------------- |   ------------------ |   ------------------------- |  
| 14                | 480                 | 39.93%                     |
| 13                | 82                  | 46.76%                     |
| 12                | 65                  | 52.16%                     |
| 11                | 94                  | 59.98%                     |
| 10                | 86                  | 67.14%                     |
| 9                 | 95                  | 75.04%                     |
| 8                 | 67                  | 80.62%                     |
| 7                 | 90                  | 88.10%                     |
| 6                 | 33                  | 90.85%                     |
| 5                 | 38                  | 94.01%                     |
| 4                 | 32                  | 96.67%                     |
| 3                 | 15                  | 97.92%                     |
| 2                 | 12                  | 98.92%                     |
| 1                 | 13                  | 100.00%                    |

Total months 6 and below passes the 90% cumulative percentage value. 

3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
```sql
SELECT COUNT(*) as data_count
FROM
	(SELECT 
		*,
		COUNT(month_year) OVER(PARTITION BY interest_id) as total_months 
	FROM interest_metrics) as t
WHERE total_months<=6;
```
| data_count      |
 |  ------------- |  
| 598             |

There are 598 data points to be removed.

4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

This decision makes sense if we want to track the customer's interests. If there is an interest where present in all 14 months, that the customer interest in that particular segment is long enough, we can expect the customers to retain the interest in months 15 and further.. But, I think we can be more selective to remove the data. For example, for `interest_id` 48154:
```sql
SELECT t.*, m.interest_name, m.interest_summary
FROM
	(SELECT 
		*,
		COUNT(month_year) OVER(PARTITION BY interest_id) as total_months 
	FROM interest_metrics) as t
JOIN interest_map as m
	ON m.id = t.interest_id
WHERE interest_id = 48154;
```
| _month      | _year      | month_year      | interest_id      | composition      | index_value      | ranking      | percentile_ranking      | total_months      | interest_name      | interest_summary      |
 |  --------- |   --------- |   -------------- |   --------------- |   --------------- |   --------------- |   ----------- |   ---------------------- |   ---------------- |   ----------------- |   -------------------- |  
| 4           | 2019       | 2019-04-00      | 48154            | 4.28             | 2.61             | 6            | 99.45                   | 5                 | Elite Cycling Gear Shoppers | Consumers researching and shopping for elite cycling equipment, apparel and accessories. |
| 5           | 2019       | 2019-05-00      | 48154            | 3.46             | 2.92             | 7            | 99.18                   | 5                 | Elite Cycling Gear Shoppers | Consumers researching and shopping for elite cycling equipment, apparel and accessories. |
| 6           | 2019       | 2019-06-00      | 48154            | 3.34             | 3.14             | 12           | 98.54                   | 5                 | Elite Cycling Gear Shoppers | Consumers researching and shopping for elite cycling equipment, apparel and accessories. |
| 7           | 2019       | 2019-07-00      | 48154            | 4.07             | 3.39             | 6            | 99.31                   | 5                 | Elite Cycling Gear Shoppers | Consumers researching and shopping for elite cycling equipment, apparel and accessories. |
| 8           | 2019       | 2019-08-00      | 48154            | 4.75             | 3.27             | 8            | 99.3                    | 5                 | Elite Cycling Gear Shoppers | Consumers researching and shopping for elite cycling equipment, apparel and accessories. |

This particular interest, while only appearing for the last 5 months, has a high composition and index_value, even in the top 12. I don't think removing this interest is a good decision. We can expect this interest will retain in the next month, with those high ranking and at the latest date.

5. After removing these interests - how many unique interests are there for each month?
```sql
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
```

| month_year      | total_interest_after      | total_interest_before      |
 |  ------------- |   ------------------------ |   ------------------------- |  
| 2018-07-00      | 701                       | 729                        |
| 2018-08-00      | 743                       | 767                        |
| 2018-09-00      | 767                       | 780                        |
| 2018-10-00      | 844                       | 857                        |
| 2018-11-00      | 919                       | 928                        |
| 2018-12-00      | 976                       | 995                        |
| 2019-01-00      | 957                       | 973                        |
| 2019-02-00      | 1050                      | 1121                       |
| 2019-03-00      | 1046                      | 1136                       |
| 2019-04-00      | 1013                      | 1099                       |
| 2019-05-00      | 817                       | 857                        |
| 2019-06-00      | 792                       | 824                        |
| 2019-07-00      | 823                       | 864                        |
| 2019-08-00      | 1033                      | 1149                       |

## C. Segment Analysis

1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
```sql
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
```

| month_year      | interest_id      | interest_name      | max_or_min_composition      | ranking      |
 |  ------------- |   --------------- |   ----------------- |   ------------------- |   ----------- |  
| 2018-12-00      | 21057            | Work Comes First Travelers | 21.2                 | top 10       |
| 2018-07-00      | 6284             | Gym Equipment Owners | 18.82                | top 10       |
| 2018-07-00      | 39               | Furniture Shoppers | 17.44                | top 10       |
| 2018-07-00      | 77               | Luxury Retail Shoppers | 17.19                | top 10       |
| 2018-10-00      | 12133            | Luxury Boutique Hotel Researchers | 15.15                | top 10       |
| 2018-12-00      | 5969             | Luxury Bedding Shoppers | 15.05                | top 10       |
| 2018-07-00      | 171              | Shoe Shoppers      | 14.91                | top 10       |
| 2018-07-00      | 4898             | Cosmetics and Beauty Shoppers | 14.23                | top 10       |
| 2018-07-00      | 6286             | Luxury Hotel Guests | 14.1                 | top 10       |
| 2018-07-00      | 4                | Luxury Retail Researchers | 13.97                | top 10       |
| 2019-05-00      | 4918             | Gastrointestinal Researchers | 1.52                 | bottom 10    |
| 2019-06-00      | 35742            | Disney Fans        | 1.52                 | bottom 10    |
| 2019-05-00      | 20768            | Beer Aficionados   | 1.52                 | bottom 10    |
| 2019-06-00      | 34083            | New York Giants Fans | 1.52                 | bottom 10    |
| 2019-05-00      | 39336            | Philadelphia 76ers Fans | 1.52                 | bottom 10    |
| 2019-05-00      | 6127             | LED Lighting Shoppers | 1.53                 | bottom 10    |
| 2019-06-00      | 6314             | Online Directory Searchers | 1.53                 | bottom 10    |
| 2019-05-00      | 36877            | Crochet Enthusiasts | 1.53                 | bottom 10    |
| 2019-06-00      | 18203            | Hunters            | 1.54                 | bottom 10    |
| 2019-05-00      | 18620            | Mexican Food Enthusiasts | 1.54                 | bottom 10    |

2. Which 5 interests had the lowest average ranking value?
```sql
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
```
| interest_id      | interest_name      | composition      |
 |  -------------- |   ----------------- |   --------------- |  
| 19599            | Dodge Vehicle Shoppers | 1.76             |
| 5900             | Dentures           | 1.79             |
| 22408            | Super Mario Bros Fans | 1.80             |
| 19591            | Camaro Enthusiasts | 1.81             |
| 37412            | Medieval History Enthusiasts | 1.82             |

3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
```sql
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
```

4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
```sql
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
```
| interest_id      | interest_name      | min_composition      | min_month_year      | max_composition      | max_month_year      | stdev_composition      |
 |  -------------- |   ----------------- |   ------------------- |   ------------------ |   ------------------- |   ------------------ |   --------------------- |  
| 10977            | Christmas Celebration Researchers | 3.24                 | 2019-06-00          | 12.16                | 2018-10-00          | 7.12                   |
| 12133            | Luxury Boutique Hotel Researchers | 4.21                 | 2019-06-00          | 15.15                | 2018-10-00          | 3.78                   |
| 21057            | Work Comes First Travelers | 10.95                | 2018-07-00          | 21.2                 | 2018-12-00          | 9.98                   |
| 6284             | Gym Equipment Owners | 6.94                 | 2019-06-00          | 18.82                | 2018-07-00          | 3.75                   |
| 77               | Luxury Retail Shoppers | 5.53                 | 2019-06-00          | 17.19                | 2018-07-00          | 4.99                   |

The first three interests are seasonal. When around Christmas or December, more people will likely book hotel or travel because of vacation. For the last two, it seems like the customers lose interests over time for the products. 


5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

If we look at the table from the first question, seems like the customers love luxury products (fashion, accessories, bedding, gift, and hotel), cosmetics, shoes, and gym equipment. We should show hotel services and fashion product more often. The least intereests are Disney, craft beer, LED lightning, croceth and hunting equipment, Mexican food, online dictionaries, New York Giant and Philadelphia 76ers fans, and gastrointestinal. Thses products and services can be avoided. 

## D. Index Analysis

1. What is the top 10 interests by the average composition for each month?
```sql
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
```
| month_year      | interest_id      | interest_name      | composition      | index_value      | avg_composition      | avg_comp_rank      |
 |  ------------- |   --------------- |   ----------------- |   --------------- |   --------------- |   ------------------- |   ----------------- |  
| 2018-07-00      | 6324             | Las Vegas Trip Planners | 10.3             | 1.4              | 7.36                 | 1                  |
| 2018-07-00      | 6284             | Gym Equipment Owners | 18.82            | 2.71             | 6.94                 | 2                  |
| 2018-07-00      | 4898             | Cosmetics and Beauty Shoppers | 14.23            | 2.1              | 6.78                 | 3                  |
| 2018-07-00      | 77               | Luxury Retail Shoppers | 17.19            | 2.6              | 6.61                 | 4                  |
| 2018-07-00      | 39               | Furniture Shoppers | 17.44            | 2.68             | 6.51                 | 5                  |
| 2018-07-00      | 18619            | Asian Food Enthusiasts | 9.15             | 1.5              | 6.10                 | 6                  |

2. For all of these top 10 interests - which interest appears the most often?
```sql
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
```
| interest_id      | interest_name      | total_appear      |
 |  -------------- |   ----------------- |   ---------------- |  
| 7541             | Alabama Trip Planners | 10                |
| 5969             | Luxury Bedding Shoppers | 10                |
| 6065             | Solar Energy Researchers | 10                |
| 21245            | Readers of Honduran Content | 9                 |
| 18783            | Nursing and Physicians Assistant Journal Researchers | 9                 |

3. What is the average of the average composition for the top 10 interests for each month?
```sql
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
```

| month_year      | avg_of_avg_comp      |
 |  ------------- |   ------------------- |  
| 2018-07-00      | 6.04                 |
| 2018-08-00      | 5.94                 |
| 2018-09-00      | 6.89                 |
| 2018-10-00      | 7.07                 |
| 2018-11-00      | 6.62                 |
| 2018-12-00      | 6.65                 |
| 2019-01-00      | 6.40                 |
| 2019-02-00      | 6.58                 |
| 2019-03-00      | 6.17                 |
| 2019-04-00      | 5.75                 |
| 2019-05-00      | 3.54                 |
| 2019-06-00      | 2.43                 |
| 2019-07-00      | 2.76                 |
| 2019-08-00      | 2.63                 |

4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
```sql
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
```

| month_year      | interest_name      | max_avg_composition      | 3_month_moving_avg      | 1_month_ago      | 2_months_ago      |
 |  ------------- |   ----------------- |   ----------------------- |   ---------------------- |   --------------- |   ---------------- |  
| 2018-09-00      | Work Comes First Travelers | 8.26                     | 6.25                    | Las Vegas Trip Planners: 7.21 | Las Vegas Trip Planners: 7.36 |
| 2018-10-00      | Work Comes First Travelers | 9.14                     | 7.70                    | Work Comes First Travelers: 8.26 | Las Vegas Trip Planners: 7.21 |
| 2018-11-00      | Work Comes First Travelers | 8.28                     | 8.56                    | Work Comes First Travelers: 9.14 | Work Comes First Travelers: 8.26 |
| 2018-12-00      | Work Comes First Travelers | 8.31                     | 8.58                    | Work Comes First Travelers: 8.28 | Work Comes First Travelers: 9.14 |
| 2019-01-00      | Work Comes First Travelers | 7.66                     | 8.08                    | Work Comes First Travelers: 8.31 | Work Comes First Travelers: 8.28 |
| 2019-02-00      | Work Comes First Travelers | 7.66                     | 7.88                    | Work Comes First Travelers: 7.66 | Work Comes First Travelers: 8.31 |
| 2019-03-00      | Alabama Trip Planners | 6.54                     | 6.55                    | Work Comes First Travelers: 7.66 | Work Comes First Travelers: 7.66 |
| 2019-04-00      | Solar Energy Researchers | 6.28                     | 6.42                    | Alabama Trip Planners: 6.54 | Work Comes First Travelers: 7.66 |
| 2019-05-00      | Readers of Honduran Content | 4.41                     | 5.55                    | Solar Energy Researchers: 6.28 | Alabama Trip Planners: 6.54 |
| 2019-06-00      | Las Vegas Trip Planners | 2.77                     | 3.52                    | Readers of Honduran Content: 4.41 | Solar Energy Researchers: 6.28 |
| 2019-07-00      | Las Vegas Trip Planners | 2.82                     | 2.89                    | Las Vegas Trip Planners: 2.77 | Readers of Honduran Content: 4.41 |
| 2019-08-00      | Cosmetics and Beauty Shoppers | 2.73                     | 2.69                    | Las Vegas Trip Planners: 2.82 | Las Vegas Trip Planners: 2.77 |

5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
I don't really understand this average_composition metric for. I can only say because the composition and index_value is for a particular month, the average composition should also be different each month.
