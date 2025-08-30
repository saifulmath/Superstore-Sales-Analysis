SELECT * FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table` LIMIT 1000;

---Key Performance Indicators (KPIs)

WITH base_data AS (
  SELECT 
    `Order ID`,
    `Customer ID`,
    SAFE_CAST(Sales AS FLOAT64) AS Sales,
    SAFE_CAST(Profit AS FLOAT64) AS Profit,
    CASE 
      WHEN LOWER(status) = 'returned' THEN TRUE
      ELSE FALSE
    END AS Returned
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  )

  SELECT
  COUNT(DISTINCT `Order ID`) AS total_orders,
  COUNT(DISTINCT `Customer ID`) AS total_customers,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Sales) / COUNT(DISTINCT `Order ID`), 2) AS avg_order_value,
  ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS profit_margin_pct,
  ROUND(SUM(CASE WHEN Returned THEN 1 ELSE 0 END) / COUNT(DISTINCT `Order ID`) * 100, 2) AS return_rate_pct
  FROM base_data;

  ---Product & Category Performance

  -- 1. What are the top-selling categories and sub-categories?
 
SELECT
  `Product Category`,
  `Product Sub-Category`,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Product Category`, `Product Sub-Category`
ORDER BY total_sales DESC
LIMIT 10;
---Insight: This shows you which sub-categories drive the most revenue (and their profit margins).

---2. Which products have high revenue but low profit?

SELECT
  `Product Name`,
  ROUND(SUM(Sales),2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Product Name`
HAVING total_sales > 40000 AND total_profit < 100 
ORDER BY total_sales DESC;
---Insight: Helps identify revenue-driving products that are underperforming in profit (e.g., due to high discounts or costs).

---3. Profit vs. Discount Scatter Plot
SELECT
  `Product Name`,
  ROUND(AVG(Discount), 2) AS avg_discount,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Sales), 2) AS total_sales,
  COUNT(DISTINCT `Order ID`) AS num_orders
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Product Name`
HAVING total_sales > 10000
ORDER BY avg_discount DESC;
---This visually detect over-discounting (e.g., high discounts leading to low or negative profit).


SELECT * FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table` LIMIT 1000;

--- Regional and Geographic Analysis
---Sales & Profit by State, City, and Region

SELECT
  `Region`,
  `State or Province`,
  `City`,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct,
  COUNT(DISTINCT `Order ID`) AS total_orders,
  CASE 
   WHEN SUM(Profit) < 0 THEN 'Underperforming'
   ELSE 'Profitable'
   END AS performance_status
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Region`, `State or Province`, `City`
ORDER BY total_profit ASC;

SELECT
  `Region`,
  `State or Province`,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Region`, `State or Province`
ORDER BY total_profit ASC;

---Time Series Trends

--1. Sales by Month
SELECT
  FORMAT_DATE('%Y-%m', DATE(`Order Date`)) AS year_month,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY year_month
ORDER BY year_month;

--2. Sales by Quarter
SELECT
  CONCAT(EXTRACT(YEAR FROM DATE(`Order Date`)), '-Q', EXTRACT(QUARTER FROM DATE(`Order Date`))) AS year_quarter,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY year_quarter
ORDER BY year_quarter;

--3. Sales by Year (YoY Trend)
SELECT
  EXTRACT(YEAR FROM DATE(`Order Date`)) AS year,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY year
ORDER BY year;

--4. Month-over-Month (MoM) Growth
WITH monthly_sales AS (
  SELECT
    DATE_TRUNC(DATE(`Order Date`), MONTH) AS month_start,
    ROUND(SUM(Sales), 2) AS total_sales
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  GROUP BY month_start
)
SELECT
  month_start,
  total_sales,
  LAG(total_sales) OVER (ORDER BY month_start) AS prev_month_sales,
  ROUND((total_sales - LAG(total_sales) OVER (ORDER BY month_start)) / 
        LAG(total_sales) OVER (ORDER BY month_start) * 100, 2) AS MoM_growth_pct
FROM monthly_sales
ORDER BY month_start;

--5. Year-over-Year (YoY) Growth
WITH yearly_sales AS (
  SELECT
    EXTRACT(YEAR FROM DATE(`Order Date`)) AS year,
    ROUND(SUM(Sales), 2) AS total_sales
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  GROUP BY year
)
SELECT
  year,
  total_sales,
  LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
  ROUND((total_sales - LAG(total_sales) OVER (ORDER BY year)) /
        LAG(total_sales) OVER (ORDER BY year) * 100, 2) AS YoY_growth_pct
FROM yearly_sales
ORDER BY year;

--Add Seasonality Indicators (e.g., holiday boost)
--I want to flag months like November/December (holiday season):
SELECT
  FORMAT_DATE('%Y-%m', DATE(`Order Date`)) AS year_month,
  ROUND(SUM(Sales), 2) AS total_sales,
  CASE 
    WHEN EXTRACT(MONTH FROM DATE(`Order Date`)) IN (11, 12) THEN 'Holiday Season'
    ELSE 'Regular Season'
  END AS season_type
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY year_month, season_type
ORDER BY year_month;

---Customer Segmentation & Lifetime Value

SELECT
  MAX(total_sales) AS max_total_sales, ----123,745.62
  MIN(total_sales) AS min_total_sales, ---3.17
  MAX(total_profit) AS max_total_profit, ---17,536.85
  MIN(total_profit) AS min_total_profit --- (-)15,865.72 negative
FROM (
  SELECT
    `Customer ID`,
    SUM(Sales) AS total_sales,
    SUM(Profit) AS total_profit
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  GROUP BY `Customer ID`);


--1. Customer Segmentation: High Sales / High Profit
SELECT
  `Customer ID`,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  COUNT(DISTINCT `Order ID`) AS total_orders,
  CASE 
    WHEN SUM(Sales) >= 50000 AND SUM(Profit) >= 1000 THEN 'High Value'
    WHEN SUM(Sales) >= 50000 THEN 'High Revenue, Low Profit'
    WHEN SUM(Profit) >= 1000 THEN 'Low Revenue, High Profit'
    ELSE 'Low Value'
  END AS customer_segment
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Customer ID`
ORDER BY total_sales DESC;

-- 2. Repeat Buyers vs. One-Time Buyers
SELECT
  `Customer ID`,
  `Customer Name`,
  COUNT(DISTINCT `Order ID`) AS total_orders,
  CASE
    WHEN COUNT(DISTINCT `Order ID`) = 1 THEN 'One-Time Buyer'
    ELSE 'Repeat Buyer'
  END AS buyer_type
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Customer ID`,`Customer Name`;

--3. Customer Churn Analysis

-- Step 0: Get the last business date from the dataset
WITH last_business_date AS (
  SELECT MAX(DATE(`Order Date`)) AS last_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

-- Step 1: Get the last purchase date per customer
customer_last_purchase AS (
  SELECT
    `Customer ID`,
    MAX(DATE(`Order Date`)) AS last_purchase_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  GROUP BY `Customer ID`
)

-- Step 2: Calculate days since last purchase using last business date
SELECT
  clp.`Customer ID`,
  clp.last_purchase_date,
  last_date,
  DATE_DIFF(lbd.last_date, clp.last_purchase_date, DAY) AS days_since_last_purchase,
  CASE 
    WHEN DATE_DIFF(lbd.last_date, clp.last_purchase_date, DAY) > 30 THEN 'Churned'
    ELSE 'Active'
  END AS churn_status
FROM customer_last_purchase clp
CROSS JOIN last_business_date lbd
ORDER BY days_since_last_purchase DESC;

--Discount Effectiveness

--1. Discount vs. Profit Correlation per Order
SELECT
  ROUND(Discount, 2) AS discount_level,
  COUNT(*) AS order_count,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(AVG(Profit), 2) AS avg_profit_per_order,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY discount_level
ORDER BY discount_level;

--2. Discount vs. Profit Correlation per Product

SELECT
  `Product Name`,
  ROUND(Discount, 2) AS discount_level,
  COUNT(*) AS order_count,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(AVG(Profit), 2) AS avg_profit_per_order,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Product Name`, discount_level
HAVING COUNT(*) > 5
ORDER BY `Product Name`, discount_level;

--3. Profitability Buckets by Discount Range
SELECT
  CASE 
    WHEN Discount = 0 THEN 'No Discount'
    WHEN Discount > 0 AND Discount <= 0.05 THEN 'Low (0-5%)'
    WHEN Discount > 0.05 AND Discount <= 0.10 THEN 'Moderate (6-10%)'
    WHEN Discount > 0.10 AND Discount <= 0.25 THEN 'High (11-25%)'
    ELSE 'Very High (>25%)'
  END AS discount_range,

  COUNT(*) AS order_count,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY discount_range
ORDER BY discount_range;

---RFM Segmentation
WITH customer_orders AS (
  SELECT
    `Customer ID`,
    `Customer Name`,
    DATE(`Order Date`) AS order_date,
    SAFE_CAST(Sales AS FLOAT64) AS sales
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

-- You can define a fixed last_business_date here (e.g., latest in dataset)
last_date AS (
  SELECT MAX(DATE(`Order Date`)) AS last_business_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

rfm_base AS (
  SELECT
    o.`Customer ID`,
    ANY_VALUE(o.`Customer Name`) AS customer_name,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT DATE(order_date)) AS frequency,
    ROUND(SUM(sales), 2) AS monetary,
    DATE_DIFF(MAX(ld.last_business_date), MAX(order_date), DAY) AS recency_days
  FROM customer_orders o
  CROSS JOIN last_date ld
  GROUP BY o.`Customer ID`
),

rfm_scored AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),

rfm_segmented AS (
  SELECT
    `Customer ID`,
    customer_name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_score,
    (r_score + f_score + m_score) AS total_rfm_score,
    
    CASE
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('455', '542', '544', '552', '553', '452', '545', '554', '555') THEN 'Champions'
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('344', '345', '353', '354', '355', '443', '451', '342', '351', '352', '441', '442', '444', '445', '453', '454', '541', '543', '515', '551') THEN 'Loyal Customers'
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('513', '413', '511', '411', '512', '341', '412', '343', '514') THEN 'Potential Loyalists'
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('414', '415', '214', '211', '212', '213', '241', '251', '312', '314', '311', '313', '315', '243', '245', '252', '253', '255', '242', '244', '254') THEN 'Promising Customers'
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('141', '142', '143', '144', '151', '152', '155', '145', '153', '154', '215') THEN 'Needs Attention'
      WHEN CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) IN 
        ('113', '111', '112', '114', '115') THEN 'At Risk'
      ELSE 'Others'
    END AS segment

  FROM rfm_scored
)


SELECT *
FROM rfm_segmented
ORDER BY segment, rfm_score DESC;

---RFM Segmentation (Alternative Method)

WITH customer_orders AS (
  SELECT
    `Customer ID`,
    `Customer Name`,
    DATE(`Order Date`) AS order_date,
    SAFE_CAST(Sales AS FLOAT64) AS sales
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

-- You can define a fixed last_business_date here (e.g., latest in dataset)
last_date AS (
  SELECT MAX(DATE(`Order Date`)) AS last_business_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

rfm_base AS (
  SELECT
    o.`Customer ID`,
    ANY_VALUE(o.`Customer Name`) AS customer_name,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT DATE(order_date)) AS frequency,
    ROUND(SUM(sales), 2) AS monetary,
    DATE_DIFF(MAX(ld.last_business_date), MAX(order_date), DAY) AS recency_days
  FROM customer_orders o
  CROSS JOIN last_date ld
  GROUP BY o.`Customer ID`
),

rfm_scored AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_base
),

rfm_segmented AS (
  SELECT
    `Customer ID`,
    customer_name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CAST(r_score AS STRING) || CAST(f_score AS STRING) || CAST(m_score AS STRING) AS rfm_score,
    (r_score + f_score + m_score) AS total_rfm_score,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
      WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
      WHEN r_score = 5 THEN 'Recent Customers'
      WHEN f_score >= 4 THEN 'Frequent Buyers'
      WHEN m_score >= 4 THEN 'Big Spenders'
      WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'At Risk'
      ELSE 'Others'
    END AS segment
  FROM rfm_scored
)

SELECT *
FROM rfm_segmented
ORDER BY segment, rfm_score DESC;