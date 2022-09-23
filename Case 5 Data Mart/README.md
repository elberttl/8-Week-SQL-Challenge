# Case Study #5 - Data Mart

- [Case Study #5 - Data Mart](#case-study-5---data-mart)
	- [A. Data Cleansing](#a-data-cleansing)
	- [B. Data Exploration](#b-data-exploration)
	- [C. Before & After Analysis](#c-before--after-analysis)
	- [D. Bonus Question](#d-bonus-question)

## A. Data Cleansing

```sql
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS
SELECT 
	STR_TO_DATE(week_date, '%d/%m/%y') as week_date,
    WEEKOFYEAR(STR_TO_DATE(week_date, '%d/%m/%y')) as week_number,
    MONTH(STR_TO_DATE(week_date, '%d/%m/%y')) as month_number,
    region,
    platform,
    (CASE WHEN segment='null' THEN 'unknown' ELSE segment END) as segment,
    (CASE 
		WHEN segment LIKE '%1%' THEN 'Young Adults'
        WHEN segment LIKE '%2%' THEN 'Middle Aged'
        WHEN segment REGEXP '[34]' THEN 'Retires' 
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

SELECT * FROM clean_weekly_sales;
```

Here is the output for the first 10 row.

| week_date      | week_number      | month_number      | region      | platform      | segment      | age_band      | demographic      | customer_type      | transactions      | sales      | avg_transactions      |
| -------------- | ---------------- | ----------------- | ----------- | ------------- | ------------ | ------------- | ---------------- | ------------------ | ----------------- | ---------- | --------------------- |
| 2018-03-26     | 13               | 3                 | CANADA      | Retail        | F2           | Middle Aged   | Families         | New                | 16700             | 632396     | 37.87                 |
| 2018-03-26     | 13               | 3                 | USA         | Retail        | C3           | Retires       | Couples          | Existing           | 77859             | 4724108    | 60.68                 |
| 2018-03-26     | 13               | 3                 | AFRICA      | Retail        | F1           | Young Adults  | Families         | New                | 23569             | 905823     | 38.43                 |
| 2018-03-26     | 13               | 3                 | EUROPE      | Retail        | F1           | Young Adults  | Families         | New                | 903               | 39900      | 44.19                 |
| 2018-03-26     | 13               | 3                 | SOUTH AMERICA | Shopify       | C1           | Young Adults  | Couples          | New                | 13                | 1864       | 143.38                |
| 2018-03-26     | 13               | 3                 | CANADA      | Shopify       | unknown      | unknown       | unknown          | New                | 52                | 8839       | 169.98                |
| 2018-03-26     | 13               | 3                 | OCEANIA     | Retail        | F1           | Young Adults  | Families         | Existing           | 126157            | 6864699    | 54.41                 |
| 2018-03-26     | 13               | 3                 | OCEANIA     | Shopify       | C4           | Retires       | Couples          | Existing           | 425               | 77934      | 183.37                |
| 2018-03-26     | 13               | 3                 | EUROPE      | Retail        | C2           | Middle Aged   | Couples          | Existing           | 7452              | 373224     | 50.08                 |
| 2018-03-26     | 13               | 3                 | CANADA      | Shopify       | C1           | Young Adults  | Couples          | New                | 52                | 6622       | 127.35                |

## B. Data Exploration

1. What day of the week is used for each week_date value?
```sql
SELECT DISTINCT(DAYNAME(week_date)) as day FROM clean_weekly_sales;
```

| day      |
| -------- |
| Monday   |

From the `clean_weekly_sales` we can see that the `week_date` value for each row has a different of 7 days (or the same as the row before). The day that is used is Monday.

2. What range of week numbers are missing from the dataset?

``` sql
DROP TABLE IF EXISTS all_weeks;
CREATE TABLE all_weeks AS
	SELECT ROW_NUMBER() OVER (ORDER BY week_date) as week
	FROM clean_weekly_sales
	LIMIT 52;

SELECT DISTINCT week
FROM clean_weekly_sales
RIGHT JOIN all_weeks
	ON week_number = week
WHERE week_number IS NULL;
```

The first 4 row output of the above queries is as the table below (I cut it so it's not too long). The answer is week 1-12, and 37-52

| week      |
| --------- |
| 1         |
| 2         |
| 3         |
| 4         |



3. How many total transactions were there for each year in the dataset?

```sql
SELECT calendar_year, SUM(transactions) as total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year;
```

| calendar_year      | total_transactions      |
| ------------------ | ----------------------- |
| 2018               | 346406460               |
| 2019               | 365639285               |
| 2020               | 375813651               |

The total transactions are increased from 2018 to 2022.

4. What is the total sales for each region for each month?

```sql
SELECT region, MONTHNAME(week_date), SUM(sales) as total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;
```
| region      | MONTHNAME(week_date)      | total_sales      |
| ----------- | ------------------------- | ---------------- |
| AFRICA      | March                     | 567767480        |
| AFRICA      | April                     | 1911783504       |
| AFRICA      | May                       | 1647244738       |
| AFRICA      | June                      | 1767559760       |
| AFRICA      | July                      | 1960219710       |
| AFRICA      | August                    | 1809596890       |
| AFRICA      | September                 | 276320987        |
| ASIA        | March                     | 529770793        |
| ASIA        | April                     | 1804628707       |
| ASIA        | May                       | 1526285399       |
| ASIA        | June                      | 1619482889       |
| ASIA        | July                      | 1768844756       |
| ASIA        | August                    | 1663320609       |
| ASIA        | September                 | 252836807        |
| CANADA      | March                     | 144634329        |
| CANADA      | April                     | 484552594        |
| CANADA      | May                       | 412378365        |
| CANADA      | June                      | 443846698        |
| CANADA      | July                      | 477134947        |
| CANADA      | August                    | 447073019        |
| CANADA      | September                 | 69067959         |
| EUROPE      | March                     | 35337093         |
| EUROPE      | April                     | 127334255        |
| EUROPE      | May                       | 109338389        |
| EUROPE      | June                      | 122813826        |
| EUROPE      | July                      | 136757466        |
| EUROPE      | August                    | 122102995        |
| EUROPE      | September                 | 18877433         |
| OCEANIA     | March                     | 783282888        |
| OCEANIA     | April                     | 2599767620       |
| OCEANIA     | May                       | 2215657304       |
| OCEANIA     | June                      | 2371884744       |
| OCEANIA     | July                      | 2563459400       |
| OCEANIA     | August                    | 2432313652       |
| OCEANIA     | September                 | 372465518        |
| SOUTH AMERICA | March                     | 71023109         |
| SOUTH AMERICA | April                     | 238451531        |
| SOUTH AMERICA | May                       | 201391809        |
| SOUTH AMERICA | June                      | 218247455        |
| SOUTH AMERICA | July                      | 235582776        |
| SOUTH AMERICA | August                    | 221166052        |
| SOUTH AMERICA | September                 | 34175583         |
| USA         | March                     | 225353043        |
| USA         | April                     | 759786323        |
| USA         | May                       | 655967121        |
| USA         | June                      | 703878990        |
| USA         | July                      | 760331754        |
| USA         | August                    | 712002790        |
| USA         | September                 | 110532368        |

5. What is the total count of transactions for each platform

```sql
SELECT platform, SUM(transactions) as total_transactions_count
FROM clean_weekly_sales
GROUP BY platform;
```

| platform      | total_transactions_count      |
| ------------- | ----------------------------- |
| Retail        | 1081934227                    |
| Shopify       | 5925169                       |

The transactions count for retail platform is much higher than Shopify.

6. What is the percentage of sales for Retail vs Shopify for each month?

```sql
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
```

| calendar_year      | month      | retail_sales      | shopify_sales      | shopify_sales_percentage      | retail_sales_percentage      |
 |---------------- | --------- | ---------------- | ----------------- | ---------------------------- | --------------------------- |
| 2018               | March      | 525583061         | 11172391           | 2.08%                         | 97.92%                       |
| 2018               | April      | 2617369077        | 55435570           | 2.07%                         | 97.93%                       |
| 2018               | May        | 2080290488        | 48365936           | 2.27%                         | 97.73%                       |
| 2018               | June       | 2061128568        | 47323635           | 2.24%                         | 97.76%                       |
| 2018               | July       | 2646368290        | 60830182           | 2.25%                         | 97.75%                       |
| 2018               | August     | 2140297292        | 50244975           | 2.29%                         | 97.71%                       |
| 2018               | September  | 540134542         | 12836820           | 2.32%                         | 97.68%                       |
| 2019               | March      | 567984858         | 13332196           | 2.29%                         | 97.71%                       |
| 2019               | April      | 2836349313        | 63798008           | 2.20%                         | 97.80%                       |
| 2019               | May        | 2221160706        | 56371106           | 2.48%                         | 97.52%                       |
| 2019               | June       | 2181126868        | 57727053           | 2.58%                         | 97.42%                       |
| 2019               | July       | 2785870177        | 75766614           | 2.65%                         | 97.35%                       |
| 2019               | August     | 2240942490        | 64297818           | 2.79%                         | 97.21%                       |
| 2019               | September  | 564372315         | 16932978           | 2.91%                         | 97.09%                       |
| 2020               | March      | 1205620498        | 33475731           | 2.70%                         | 97.30%                       |
| 2020               | April      | 2281873844        | 71478722           | 3.04%                         | 96.96%                       |
| 2020               | May        | 2284387029        | 77687860           | 3.29%                         | 96.71%                       |
| 2020               | June       | 2807693824        | 92714414           | 3.20%                         | 96.80%                       |
| 2020               | July       | 2255852981        | 77642565           | 3.33%                         | 96.67%                       |
| 2020               | August     | 2810210216        | 101583216          | 3.49%                         | 96.51%                       |

Almost all transactions are done from retail platform, but the percentage for Shopify gradually increases as the time goes.

7. What is the percentage of sales by demographic for each year in the dataset?

```sql
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
```

| calendar_year      | families_percentage      | couples_percentage      | unknown_percentage      |
 |---------------- | ----------------------- | ---------------------- | ---------------------- |
| 2018               | 32%                      | 26%                     | 42%                     |
| 2019               | 32%                      | 27%                     | 40%                     |
| 2020               | 33%                      | 29%                     | 39%                     |

8. Which age_band and demographic values contribute the most to Retail sales?

```sql
SELECT 
	 a.age_band, 
     a.demographic, 
     CONCAT(FORMAT(a.sales/total_sales*100, 1), '%') percentage
FROM clean_weekly_sales as s
JOIN (SELECT SUM(sales) as total_sales FROM clean_weekly_sales) as total_sales
JOIN (SELECT age_band, demographic, SUM(sales) as sales FROM clean_weekly_sales GROUP BY age_band, demographic) as a
	ON s.age_band = a.age_band AND s.demographic = a.demographic
GROUP BY age_band, demographic;
```

| age_band      | demographic      | percentage      |
 |----------- | --------------- | -------------- |
| Middle Aged   | Families         | 11.2%           |
| Retirees      | Couples          | 16.0%           |
| Young Adults  | Families         | 4.7%            |
| Young Adults  | Couples          | 6.6%            |
| unknown       | unknown          | 40.1%           |
| Middle Aged   | Couples          | 4.9%            |
| Retirees      | Families         | 16.6%           |

9.  Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

```sql
SELECT 
	calendar_year, 
    platform, 
    FORMAT(SUM(sales)/SUM(transactions), 2) as avg_transactions, 
    FORMAT(AVG(avg_transactions), 2) as avg_of_avg_transactions
FROM clean_weekly_sales
GROUP BY calendar_year, platform;
```

| calendar_year      | platform      | avg_transactions      | avg_of_avg_transactions      |
 |---------------- | ------------ | -------------------- | --------------------------- |
| 2018               | Retail        | 36.56                 | 42.91                        |
| 2018               | Shopify       | 192.48                | 188.28                       |
| 2019               | Retail        | 36.83                 | 41.97                        |
| 2019               | Shopify       | 183.36                | 177.56                       |
| 2020               | Shopify       | 179.03                | 174.87                       |
| 2020               | Retail        | 36.56                 | 40.64                        |

We cannot use `avg_transactions` column (from `clean_weekly_sales` table) to calculate the aerage transactiosn for each platform. The average of average transactions is not the same as average transactions. By definition, average transactions can be calculated by the following expression:

$$
avg(transactions) = \frac{\sum sales}{\sum transactions}
$$

While the average of average transactions can be expressed as:

$$
avg(avg\_transactions) = \frac{\sum \frac{sales}{transactions}}{count_\_of\_avg\_transactions}
$$

## C. Before & After Analysis

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

```sql
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
```

| before_change      | after_change      | reduction_rate      | reduction_percentage      |
 |---------------- | ---------------- | ------------------ | ------------------------ |
| 2345878357         | 2318994169        | -26884188           | -1.15%                    |

After the change was made, sales are reduced by -1.15%.

2. What about the entir 12 weeks before and after?

```sql
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
```

| before_change      | after_change      | reduction_rate      | reduction_percentage      |
 |---------------- | ---------------- | ------------------ | ------------------------ |
| 7126273147         | 6973947753        | -152325394          | -2.14%                    |

After observing the change for 8 weeks more, turns out sales are reduced by -2.14%. This value is almost double than the 4 weeks interval. This change is not desireable and negatively impact the business. 

3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

For the 4 weeks period:

```sql
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
```

| 2018               | 2125140809          | 2129242914         | 4102105         | 0.19%           |
| 2019               | 2249989796          | 2252326390         | 2336594         | 0.10%           |
| 2020               | 2345878357          | 2318994169         | -26884188       | -1.15%          |

For the 12 weeks period, just change the interval in the case operator, the output:

| calendar_year      | before_june_15      | after_june_15      | difference      | percentage      |
 |---------------- | ------------------ | ----------------- | -------------- | -------------- |
| 2018               | 6396562317          | 6500818510         | 104256193       | 1.63%           |
| 2019               | 6883386397          | 6862646103         | -20740294       | -0.30%          |
| 2020               | 7126273147          | 6973947753         | -152325394      | -2.14%          |

If we look at the 4 weeks period, each year the sales are increased. Before and after June 15 for year 2018 and 2019 the sales are increased a bit. Only after the change was made the sales are decreased. We can compare the percentage, with the increase of only about 0.1-0.2%, and the decrease is -1.15%. That is about 5-10 times the increase. For the 12 weeks period, in 2018 the sales percentage increased moderately. In 2019, there are a bit of decreased. But in 2020, the sales decreased a lot.

## D. Bonus Question

Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

The query for region:
```sql
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
```

| region      | before_change      | after_change      | difference      | percentage      |
 |--------- | ----------------- | ---------------- | -------------- | -------------- |
| CANADA      | 426438454          | 418264441         | -8174013        | -1.92%          |
| USA         | 677013558          | 666198715         | -10814843       | -1.60%          |
| AFRICA      | 1709537105         | 1700390294        | -9146811        | -0.54%          |
| EUROPE      | 108886567          | 114038959         | 5152392         | 4.73%           |
| SOUTH AMERICA | 213036207          | 208452033         | -4584174        | -2.15%          |
| OCEANIA     | 2354116790         | 2282795690        | -71321100       | -3.03%          |
| ASIA        | 1637244466         | 1583807621        | -53436845       | -3.26%          |

Asia and Oceania have the highest negative impact after the change was made. Unexceptedly, the change is well received in Europe.

As for the other metrics performance, `region` column can be changed to the other desired metric. Here's the output of some other metrics:

| platform      | before_change      | after_change      | difference      | percentage      |
 |----------- | ----------------- | ---------------- | -------------- | -------------- |
| Retail        | 6906861113         | 6738777279        | -168083834      | -2.43%          |
| Shopify       | 219412034          | 235170474         | 15758440        | 7.18%           |

| age_band      | before_change      | after_change      | difference      | percentage      |
 |----------- | ----------------- | ---------------- | -------------- | -------------- |
| Middle Aged   | 1164847640         | 1141853348        | -22994292       | -1.97%          |
| Retirees      | 2395264515         | 2365714994        | -29549521       | -1.23%          |
| Young Adults  | 801806528          | 794417968         | -7388560        | -0.92%          |
| unknown       | 2764354464         | 2671961443        | -92393021       | -3.34%          |

| demographic      | before_change      | after_change      | difference      | percentage      |
 |-------------- | ----------------- | ---------------- | -------------- | -------------- |
| Families         | 2328329040         | 2286009025        | -42320015       | -1.82%          |
| Couples          | 2033589643         | 2015977285        | -17612358       | -0.87%          |
| unknown          | 2764354464         | 2671961443        | -92393021       | -3.34%          |

| customer_type      | before_change      | after_change      | difference      | percentage      |
 |---------------- | ----------------- | ---------------- | -------------- | -------------- |
| New                | 862720419          | 871470664         | 8750245         | 1.01%           |
| Existing           | 3690116427         | 3606243454        | -83872973       | -2.27%          |
| Guest              | 2573436301         | 2496233635        | -77202666       | -3.00%          |