# Superstore-Sales-Analysis
Python, Google BigQuery, Google Sheets

📌 Project Overview

This project analyzes Superstore sales data to uncover insights into profitability, customer behavior, regional trends, and discount effectiveness.
The workflow includes cleaning data in Python, storing it in BigQuery, analyzing it with SQL, and visualizing it in Google Sheets dashboards.

🛠️ Work Procedure

1. Reading Data

   🔹 Imported raw data from Google Sheets (Superstore dataset).

2. Exploratory Data Analysis (EDA)

   🔹 Performed using Python (pandas, matplotlib).

3. Data Cleaning in Python

   🔹 Removed null values/ duplicate values, fixed data types (e.g., Order Date, Sales, Profit).

4. Creating a Denormalized Table in Python

   🔹 Joined multiple sheets (Orders, Returns, Customers, Users) into a single consolidated dataset.

5. BigQuery Integration

   🔹 Uploaded denormalized dataset to Google BigQuery for analysis.

6. SQL Analysis

   * Wrote queries for:

       🔹Product & Category Performance

       🔹Customer Segmentation (RFM, Churn, Repeat Buyers)

       🔹Discount Effectiveness

       🔹Regional & Time Series Trends

7. Visualization

   🔹Exported SQL results to Google Sheets.

   🔹Created interactive dashboards with charts, slicers, and KPIs.

📂 SQL Queries & Outputs
 ## 1: Key Performance Indicators (KPIs)
  ```sql
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
   ```

--Output--

| total_orders | total_customers |  total_sales  | total_profit | avg_order_value | profit_margin_pct | return_rate_pct |
|--------------|-----------------|---------------|--------------|-----------------|-------------------|-----------------|
| 6,455        | 2,703           | 8,951,849.54  | 1,312,442.40 | 1,386.81        | 14.66             | 1.52            |

 ## 2: What are the top-selling categories and sub-categories?
  ```sql
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
   ```

--Output--

| Product Category | Product Sub-Category              | total_sales  | total_profit | profit_margin_pct |
|------------------|-----------------------------------|--------------|--------------|-------------------|
| Technology       | Office Machines                   | 1,218,656.59 | 168,072.83   | 13.79             |
| Furniture        | Chairs & Chairmats                | 1,164,584.16 | 165,348.88   | 14.20             |
| Technology       | Telephones and Communication      | 1,144,272.98 | 297,950.52   | 26.04             |
| Furniture        | Tables                            | 1,061,921.06 | -72,495.06   | -6.83             |
| Technology       | Copiers and Fax                   |   661,211.93 | 129,156.68   | 19.53             |
| Office Supplies  | Binders and Binder Accessories    |   638,582.09 | 226,572.52   | 35.48             |
| Office Supplies  | Storage & Organization            |   585,704.91 |   8,078.80   | 1.38              |
| Furniture        | Bookcases                         |   507,494.49 |  -7,708.75   | -1.52             |
| Technology       | Computer Peripherals              |   490,840.53 |  87,917.84   | 17.91             |
| Office Supplies  | Appliances                        |   456,723.08 | 121,651.39   | 26.64             |

 ## 3: Which products have high revenue but low profit?
  ```sql
  SELECT
  `Product Name`,
  ROUND(SUM(Sales),2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY `Product Name`
HAVING total_sales > 40000 AND total_profit < 100 
ORDER BY total_sales DESC;
   ```

--Output--
| Product Name                                                                                     | total_sales | total_profit | profit_margin_pct |
|--------------------------------------------------------------------------------------------------|-------------|--------------|-------------------|
| Canon imageCLASS 2200 Advanced Copier                                                            | 107,697.73  |  -5,665.44   | -5.26             |
| Polycom ViewStation™ ISDN Videoconferencing Unit                                                  |  92,916.02  | -36,446.42   | -39.23            |
| Chromcraft Bull-Nose Wood 48" x 96" Rectangular Conference Tables                                |  92,208.46  |  -6,803.30   | -7.38             |
| BoxOffice By Design Rectangular and Half-Moon Meeting Room Tables                                |  63,825.89  | -11,541.18   | -18.08            |
| Hon 2090 “Pillow Soft” Series Mid Back Swivel/Tilt Chairs                                        |  62,752.64  |  -2,186.86   | -3.48             |
| Office Star - Contemporary Task Swivel chair with 2-way adjustable arms, Plum                    |  50,662.37  |  -7,273.53   | -14.36            |
| Hon 94000 Series Round Tables                                                                    |  48,347.71  |  -2,339.69   | -4.84             |
| Global High-Back Leather Tilter, Burgundy                                                        |  48,293.09  | -23,236.84   | -48.12            |
| Epson DFX-8500 Dot Matrix Printer                                                                |  44,980.23  | -29,557.67   | -65.71            |

---Insight: Helps identify revenue-driving products that are underperforming in profit (e.g., due to high discounts or costs).

 ## 4: Regional and Geographic Analysis
---Sales & Profit by State, City, and Region
  ```sql
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
ORDER BY total_profit ASC
LIMIT 10;
   ```
--Output--
| Region | State or Province | City              | total_sales | total_profit | profit_margin_pct | total_orders | performance_status |
|--------|-----------------|-----------------|------------|-------------|-----------------|--------------|------------------|
| South  | North Carolina  | Gastonia         | 2056.76    | -15865.73   | -771.39         | 3            | Underperforming  |
| Central| Illinois        | Galesburg        | 10540.63   | -15290.48   | -145.06         | 6            | Underperforming  |
| South  | Mississippi     | Hattiesburg      | 372.8      | -14441.3    | -3873.74        | 3            | Underperforming  |
| West   | Colorado        | Durango          | 16824.78   | -13753.1    | -81.74          | 13           | Underperforming  |
| West   | Washington      | Des Moines       | 8165.21    | -13146.32   | -161.0          | 3            | Underperforming  |
| West   | Montana         | Bozeman          | 15745.16   | -12362.12   | -78.51          | 15           | Underperforming  |
| South  | Florida         | Pine Hills       | 6063.53    | -9621.04    | -158.67         | 2            | Underperforming  |
| West   | California      | Hacienda Heights | 9038.79    | -8567.01    | -94.78          | 8            | Underperforming  |
| West   | California      | Palm Springs     | 4294.78    | -8555.86    | -199.22         | 4            | Underperforming  |
| West   | Idaho           | Boise            | 16440.82   | -7951.56    | -48.36          | 17           | Underperforming  |

 ## 5: Sales by Year (YoY Trend)
  ```sql
SELECT
  EXTRACT(YEAR FROM DATE(`Order Date`)) AS year,
  ROUND(SUM(Sales), 2) AS total_sales,
  ROUND(SUM(Profit), 2) AS total_profit,
  ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS profit_margin_pct
FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
GROUP BY year
ORDER BY year;
   ```
--Output--
| Year | total_sales  | total_profit | profit_margin_pct |
|------|-------------|-------------|-----------------|
| 2010 | 1,924,332.88 | 213,324.14  | 11.09           |
| 2011 | 1,944,507.43 | 297,847.74  | 15.32           |
| 2012 | 2,230,731.18 | 354,073.57  | 15.87           |
| 2013 | 2,852,278.05 | 447,196.94  | 15.68           |

 ## 6: Year-over-Year (YoY) Growth
  ```sql
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
   ```
--Output--
| Year | total_sales  | prev_year_sales | YoY_growth_pct |
|------|-------------|----------------|----------------|
| 2010 | 1,924,332.88 |                |                |
| 2011 | 1,944,507.43 | 1,924,332.88   | 1.05           |
| 2012 | 2,230,731.18 | 1,944,507.43   | 14.72          |
| 2013 | 2,852,278.05 | 2,230,731.18   | 27.86          |

 ## 7: Month-over-Month (MoM) Growth
  ```sql
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
   ```
--Output--
| month_start | total_sales  | prev_month_sales | MoM_growth_pct |
|-------------|-------------|----------------|----------------|
| 2010-01-01  | 114,272.51  |                |                |
| 2010-02-01  | 174,831.18  | 114,272.51     | 52.99          |
| 2010-03-01  | 167,054.86  | 174,831.18     | -4.45          |
| 2010-04-01  | 187,593.11  | 167,054.86     | 12.29          |
| 2010-05-01  | 168,953.55  | 187,593.11     | -9.94          |
| 2010-06-01  | 134,426.85  | 168,953.55     | -20.44         |
| 2010-07-01  | 116,415.16  | 134,426.85     | -13.4          |
| 2010-08-01  | 160,210.30  | 116,415.16     | 37.62          |
| 2010-09-01  | 119,027.61  | 160,210.30     | -25.71         |
| 2010-10-01  | 186,998.11  | 119,027.61     | 57.1           |
| 2010-11-01  | 197,256.01  | 186,998.11     | 5.49           |
| 2010-12-01  | 197,293.63  | 197,256.01     | 0.02           |
| 2011-01-01  | 111,787.47  | 197,293.63     | -43.34         |
| 2011-02-01  | 79,533.40   | 111,787.47     | -28.85         |
| 2011-03-01  | 101,258.87  | 79,533.40      | 27.32          |
| 2011-04-01  | 83,585.65   | 101,258.87     | -17.45         |
| 2011-05-01  | 130,072.70  | 83,585.65      | 55.62          |
| 2011-06-01  | 145,837.88  | 130,072.70     | 12.12          |
| 2011-07-01  | 132,225.45  | 145,837.88     | -9.33          |
| 2011-08-01  | 115,652.75  | 132,225.45     | -12.53         |
| 2011-09-01  | 304,399.81  | 115,652.75     | 163.2          |
| 2011-10-01  | 245,227.04  | 304,399.81     | -19.44         |
| 2011-11-01  | 292,081.20  | 245,227.04     | 19.11          |
| 2011-12-01  | 202,845.21  | 292,081.20     | -30.55         |
| 2012-01-01  | 95,210.78   | 202,845.21     | -53.06         |
| 2012-02-01  | 137,747.19  | 95,210.78      | 44.68          |
| 2012-03-01  | 129,450.69  | 137,747.19     | -6.02          |
| 2012-04-01  | 136,493.76  | 129,450.69     | 5.44           |
| 2012-05-01  | 167,308.94  | 136,493.76     | 22.58          |
| 2012-06-01  | 192,961.88  | 167,308.94     | 15.33          |
| 2012-07-01  | 159,526.94  | 192,961.88     | -17.33         |
| 2012-08-01  | 136,876.73  | 159,526.94     | -14.2          |
| 2012-09-01  | 163,099.78  | 136,876.73     | 19.16          |
| 2012-10-01  | 227,464.98  | 163,099.78     | 39.46          |
| 2012-11-01  | 487,542.05  | 227,464.98     | 114.34         |
| 2012-12-01  | 197,047.46  | 487,542.05     | -59.58         |
| 2013-01-01  | 208,084.07  | 197,047.46     | 5.6            |
| 2013-02-01  | 253,558.06  | 208,084.07     | 21.85          |
| 2013-03-01  | 149,893.33  | 253,558.06     | -40.88         |
| 2013-04-01  | 175,002.86  | 149,893.33     | 16.75          |
| 2013-05-01  | 210,642.79  | 175,002.86     | 20.37          |
| 2013-06-01  | 200,665.12  | 210,642.79     | -4.74          |
| 2013-07-01  | 195,410.89  | 200,665.12     | -2.62          |
| 2013-08-01  | 218,835.26  | 195,410.89     | 11.99          |
| 2013-09-01  | 284,016.94  | 218,835.26     | 29.79          |
| 2013-10-01  | 338,330.38  | 284,016.94     | 19.12          |
| 2013-11-01  | 342,185.49  | 338,330.38     | 1.14           |
| 2013-12-01  | 275,652.86  | 342,185.49     | -19.44         |

 ## 8: Customer Segmentation & Lifetime Value
  ```sql
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
ORDER BY total_sales DESC
Limit 20;
   ```
--Output--
| Customer ID | total_sales  | total_profit | total_orders | customer_segment          |
|-------------|-------------|-------------|--------------|--------------------------|
| 3075        | 123,745.62  | 7,228.90    | 8            | High Value               |
| 308         | 89,269.70   | 6,469.93    | 15           | High Value               |
| 2571        | 86,540.75   | 7,272.49    | 6            | High Value               |
| 2107        | 83,651.70   | 9,289.94    | 13           | High Value               |
| 553         | 81,296.39   | 4,195.60    | 11           | High Value               |
| 1733        | 78,243.60   | 16,432.45   | 4            | High Value               |
| 640         | 69,118.00   | 5,529.45    | 10           | High Value               |
| 1999        | 61,610.60   | 5,504.26    | 9            | High Value               |
| 2867        | 61,298.98   | 4,556.53    | 7            | High Value               |
| 349         | 58,947.41   | -410.30     | 7            | High Revenue, Low Profit |
| 1282        | 57,021.38   | 3,484.35    | 6            | High Value               |
| 2565        | 55,793.40   | 777.48      | 4            | High Revenue, Low Profit |
| 2756        | 55,257.89   | 2,601.40    | 6            | High Value               |
| 2491        | 55,241.63   | -970.22     | 15           | High Revenue, Low Profit |
| 68          | 54,091.64   | 5,144.76    | 5            | High Value               |
| 1822        | 52,806.01   | 7,221.82    | 4            | High Value               |
| 2403        | 47,971.14   | 5,955.02    | 7            | Low Revenue, High Profit |
| 2189        | 44,016.49   | 8,654.06    | 3            | Low Revenue, High Profit |
| 3079        | 43,756.19   | 3,253.44    | 13           | Low Revenue, High Profit |
| 699         | 43,229.86   | -3,604.23   | 15           | Low Value                |

 ## 9: Customer Churn Analysis
  ```sql
-- Step 0: Get the last business date from the dataset
WITH last_business_date AS (
  SELECT MAX(DATE(`Order Date`)) AS last_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
),

-- Step 1: Get the last purchase date and customer name per customer
customer_last_purchase AS (
  SELECT
    `Customer ID`,
    MAX(`Customer Name`) AS customer_name,
    MAX(DATE(`Order Date`)) AS last_purchase_date
  FROM `advance-sql-2025.superstore_sales_analysis.denormalized_table`
  GROUP BY `Customer ID`
)

-- Step 2: Calculate days since last purchase using last business date
SELECT
  clp.`Customer ID`,
  clp.customer_name,
  clp.last_purchase_date,
  lbd.last_date,
  DATE_DIFF(lbd.last_date, clp.last_purchase_date, DAY) AS days_since_last_purchase,
  CASE 
    WHEN DATE_DIFF(lbd.last_date, clp.last_purchase_date, DAY) > 90 THEN 'Churned'
    ELSE 'Active'
  END AS churn_status
FROM customer_last_purchase clp
CROSS JOIN last_business_date lbd
ORDER BY days_since_last_purchase DESC
LIMIT 20;
   ```
--Output--
| Customer ID | customer_name         | last_purchase_date | last_date  | days_since_last_purchase | churn_status |
|-------------|----------------------|------------------|-----------|-------------------------|--------------|
| 3306        | Claire Warren        | 2010-01-04       | 2013-12-31 | 1457                    | Churned      |
| 1556        | Carol Wood           | 2010-01-06       | 2013-12-31 | 1455                    | Churned      |
| 1882        | Anita Kent           | 2010-01-09       | 2013-12-31 | 1452                    | Churned      |
| 946         | Denise Parks         | 2010-01-09       | 2013-12-31 | 1452                    | Churned      |
| 1885        | Jacob Hirsch         | 2010-01-09       | 2013-12-31 | 1452                    | Churned      |
| 624         | Terry Klein          | 2010-01-10       | 2013-12-31 | 1451                    | Churned      |
| 623         | Jenny Petty          | 2010-01-10       | 2013-12-31 | 1451                    | Churned      |
| 3246        | Wanda Harris         | 2010-01-10       | 2013-12-31 | 1451                    | Churned      |
| 366         | Patrick Rosenthal    | 2010-01-17       | 2013-12-31 | 1444                    | Churned      |
| 657         | Derek McCormick      | 2010-01-19       | 2013-12-31 | 1442                    | Churned      |
| 659         | Marjorie Arthur      | 2010-01-19       | 2013-12-31 | 1442                    | Churned      |
| 1692        | Rhonda Schroeder     | 2010-01-23       | 2013-12-31 | 1438                    | Churned      |
| 997         | Phillip Pollard      | 2010-01-24       | 2013-12-31 | 1437                    | Churned      |
| 2283        | Nancy Holden         | 2010-01-24       | 2013-12-31 | 1437                    | Churned      |
| 2775        | Theodore Rubin       | 2010-01-30       | 2013-12-31 | 1431                    | Churned      |
| 70          | Annette Boone        | 2010-02-02       | 2013-12-31 | 1428                    | Churned      |
| 2667        | Pat Baker            | 2010-02-04       | 2013-12-31 | 1426                    | Churned      |
| 142         | Brooke Weeks Taylor  | 2010-02-06       | 2013-12-31 | 1424                    | Churned      |
| 144         | Marguerite Moss      | 2010-02-06       | 2013-12-31 | 1424                    | Churned      |
| 1112        | Luis Kerr            | 2010-02-10       | 2013-12-31 | 1420                    | Churned      |

 ## 10: Profitability Buckets by Discount Range
  ```sql
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

   ```
--Output--
| discount_range   | order_count | total_sales   | total_profit | profit_margin_pct |
|-----------------|------------|--------------|-------------|-----------------|
| High (11-25%)    | 5          | 954.77       | -434.77     | -45.54          |
| Low (0-5%)       | 4,390      | 4,234,708.81 | 750,549.03  | 17.72           |
| Moderate (6-10%) | 4,183      | 3,813,075.72 | 405,370.77  | 10.63           |
| No Discount      | 848        | 903,110.24   | 156,957.37  | 17.38           |

 ## 11: RFM Segmentation
  ```sql
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
   ```
--Output-- First few rows is displayed
| Customer ID | Customer Name           | Recency (days) | Frequency | Monetary   | R Score | F Score | M Score | RFM Score | Total RFM Score | Segment   |
|-------------|------------------------|----------------|-----------|-----------|---------|---------|---------|-----------|----------------|-----------|
| 1185        | Lee Xu                 | 35             | 6         | 22952.28  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2342        | Danny Francis Bell     | 38             | 6         | 12071.02  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2669        | Annie Booth            | 70             | 4         | 12531.37  | 5       | 5       | 5       | 555       | 15             | Champions |
| 1959        | Bonnie Matthews Rowland| 54             | 12        | 40107.91  | 5       | 5       | 5       | 555       | 15             | Champions |
| 3251        | Peter Brooks           | 5              | 10        | 29810.78  | 5       | 5       | 5       | 555       | 15             | Champions |
| 272         | Eleanor Swain          | 23             | 14        | 34482.36  | 5       | 5       | 5       | 555       | 15             | Champions |
| 454         | Gayle Waller           | 23             | 4         | 4269.84   | 5       | 5       | 5       | 555       | 15             | Champions |
| 699         | Jenny Gold             | 18             | 17        | 43229.86  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2403        | Kara Gregory           | 23             | 7         | 47971.14  | 5       | 5       | 5       | 555       | 15             | Champions |
| 1088        | Jeremy Orr             | 46             | 5         | 6451.46   | 5       | 5       | 5       | 555       | 15             | Champions |
| 1793        | Derek Jernigan         | 55             | 6         | 10540.63  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2007        | Lauren West            | 37             | 9         | 8049.95   | 5       | 5       | 5       | 555       | 15             | Champions |
| 1602        | Frank Hess             | 84             | 4         | 6151.77   | 5       | 5       | 5       | 555       | 15             | Champions |
| 1490        | Leslie Duffy           | 91             | 7         | 6667.67   | 5       | 5       | 5       | 555       | 15             | Champions |
| 486         | Tracey Gross           | 51             | 4         | 7639.42   | 5       | 5       | 5       | 555       | 15             | Champions |
| 1104        | Timothy Ross           | 42             | 8         | 26259.68  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2670        | Yvonne Mann            | 19             | 5         | 36325.04  | 5       | 5       | 5       | 555       | 15             | Champions |
| 308         | Glen Caldwell          | 63             | 17        | 89269.70  | 5       | 5       | 5       | 555       | 15             | Champions |
| 1778        | Ray Oakley             | 81             | 6         | 8658.37   | 5       | 5       | 5       | 555       | 15             | Champions |
| 2107        | Leigh Burnette Hurley  | 3              | 13        | 83651.70  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2561        | Laurie Moon            | 63             | 4         | 4315.35   | 5       | 5       | 5       | 555       | 15             | Champions |
| 2617        | Gerald Crabtree        | 4              | 5         | 5296.39   | 5       | 5       | 5       | 555       | 15             | Champions |
| 894         | Gail Rankin Cole       | 6              | 9         | 16613.07  | 5       | 5       | 5       | 555       | 15             | Champions |
| 2785        | George Shields         | 24             | 4         | 16352.48  | 5       | 5       | 5       | 555       | 15             | Champions |

📊 Dashboard
## 🔗 Google Sheets Dashboard Link https://docs.google.com/spreadsheets/d/1VF9zQF9UXXvqUOWOxAP989TDXDobe_oyPYHpGhCasb0/edit?gid=323347108#gid=323347108

👉 Recommendations

 1. Optimize Discount Strategy

    🔹 “Profitability Buckets by Discount Range” shows that higher discount ranges (11–25%) hurt profitability despite driving sales.

    🔹 Recommendation: Limit high discounting and experiment with targeted promotions (e.g., loyalty-based or product-specific discounts) instead of broad discounting.
    
 2. Focus on Customer Retention & Segmentation

    🔹 RFM segmentation shows a large portion of customers are low-value or at risk, and churn analysis indicates 80% are active, but 20% are churned.

    🔹Recommendation: Launch customer retention programs (email re-engagement, loyalty rewards for “At Risk” customers) and upsell/cross-sell strategies for “Champions” and “Big Spenders.”
    
3. Regional & Product Strategy Alignment

   🔹 Some products (e.g., high-revenue but low-profit items like Epson DFX-8500) generate sales but drain profit. Also, profitability by region is uneven.

   🔹Recommendation: Reevaluate pricing and cost structure for low-margin products, and focus marketing on profitable regions while improving efficiency in underperforming ones.
