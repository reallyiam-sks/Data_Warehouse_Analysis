/*
=============================================================
Create Database and Schemas
=============================================================
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'G:\My Drive\My Projects\portfolio_project\data_warehouse_analysis\sql-data-analytics-project\datasets\csv-files\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'G:\My Drive\My Projects\portfolio_project\data_warehouse_analysis\sql-data-analytics-project\datasets\csv-files\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'G:\My Drive\My Projects\portfolio_project\data_warehouse_analysis\sql-data-analytics-project\datasets\csv-files\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

-- year with highest sale

SELECT TOP 3 
YEAR(order_date),SUM(sales_amount) as total_sales,COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY total_sales DESC

-- months with highest sale

SELECT TOP 3
FORMAT(order_date,'MMMM') as month,SUM(sales_amount) as total_sales, COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date,'MMMM')
ORDER BY total_sales DESC

-- calculate the total sale per month and the running total of sales and moving average of price over time

SELECT 
A.order_date,A.total_sales,
SUM(A.total_sales) OVER (ORDER BY A.order_date) as running_total_sales,
AVG(A.average_price) OVER(ORDER BY A.order_date) as moving_average_price
FROM
(
SELECT 
DATETRUNC(MONTH,order_date) as order_date,
SUM(sales_amount) as total_sales,
AVG(price) as average_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date)
--ORDER BY DATETRUNC(MONTH,order_date)
) AS A

-- analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales.

WITH yearly_product_sales AS
(
SELECT 
YEAR(f.order_date) as order_year,
p.product_name,
SUM(f.sales_amount) as current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key=p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
--ORDER BY YEAR(f.order_date),p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales-AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales-AVG(current_sales) OVER(PARTITION BY product_name)>0 THEN 'Above average'
	 WHEN current_sales-AVG(current_sales) OVER(PARTITION BY product_name)<0 THEN 'Below average'
	 ELSE 'Average'
END AS avg_change,
-- year-over-year analysis
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
CASE WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year)>0 THEN 'Increased'
	 WHEN current_sales-LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year)<0 THEN 'Decreased'
	 ELSE 'No change'
END AS sales_growth
FROM yearly_product_sales
ORDER BY product_name,order_year;

-- which category contributes the most to overall sales

WITH sales_by_category AS
(
SELECT 
p.category,SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key=p.product_key
GROUP BY p.category
)
SELECT 
category,
total_sales,
SUM(total_sales) OVER() as overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER())*100,2),'%') AS percentage_of_total
FROM sales_by_category;

-- segment products into cost ranges and count how many products fall into each segment

WITH cost_segment AS
(
SELECT 
product_key,
product_number,
CASE WHEN cost<100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 WHEN cost BETWEEN 1000 AND 1500 THEN '1000-1500'
	 ELSE 'Above 1500'
END AS cost_range
FROM gold.dim_products
)
SELECT 
CASE WHEN cost_range='Below 100' THEN 1
	 WHEN cost_range='100-500' THEN 2
	 WHEN cost_range='500-1000' THEN 3
	 WHEN cost_range='1000-1500' THEN 4
	 ELSE 5
END AS No,
cost_range,
COUNT(product_key) as total_products
FROM cost_segment
GROUP BY cost_range
ORDER BY No;

/* group customers into three segments based on their spending behaviour:
	VIP : customers with at least 12 months of history and spending more than 5000
	Regular : customers with at least 12 months of history but spending 5000 or less
	New : customers with a lifespan less than 12 months.
find the total number of customers by each group
*/


WITH CTE AS
(
	SELECT 
	c.customer_key,
	SUM(f.sales_amount) AS total_spending,
	MIN(f.order_date) AS first_order_date,
	MAX(f.order_date) AS last_order_date,
	DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) as months_as_customer
	FROM gold.fact_sales AS f
	LEFT JOIN gold.dim_customers as c
	ON c.customer_key=f.customer_key
	GROUP BY c.customer_key
)
SELECT
A.customer_category,
COUNT(A.customer_key) AS total_customers
FROM
(
	SELECT
	customer_key,
	total_spending,
	months_as_customer,
	CASE WHEN total_spending>5000 AND months_as_customer>12 THEN 'VIP Customer'
		 WHEN total_spending<=5000 AND months_as_customer>=12 THEN 'Regular Customer'
		 ELSE 'New Customer'
	END AS customer_category
	FROM CTE
) AS A
GROUP BY A.customer_category
ORDER BY total_customers

/*
Customer Report

Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend

*/


CREATE VIEW gold.report_customers AS

WITH base_query AS(

--Base Query: Retrieves core columns from tables

SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) AS customer_age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS (

-- Customer Aggregations: Summarizes key metrics at the customer level

SELECT 
	customer_key,
	customer_number,
	customer_name,
	customer_age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_spending,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS months_as_customer
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	customer_age
)
SELECT
customer_key,
customer_number,
customer_name,

CASE 
	 WHEN customer_age < 20 THEN 'Under 20'
	 WHEN customer_age between 20 and 29 THEN '20-29'
	 WHEN customer_age between 30 and 39 THEN '30-39'
	 WHEN customer_age between 40 and 49 THEN '40-49'
	 WHEN customer_age between 50 and 59 THEN '50-59'
	 ELSE '60 and above'
END AS age_group,
CASE 
	WHEN total_spending>5000 AND months_as_customer>12 THEN 'VIP Customer'
	WHEN total_spending<=5000 AND months_as_customer>=12 THEN 'Regular Customer'
	ELSE 'New Customer'
END AS customer_category,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
total_orders,
total_spending,
total_quantity,
total_products
months_as_customer,
-- Compuate average order value (AVO)
CASE WHEN total_spending = 0 THEN 0
	 ELSE total_spending / total_orders
END AS avg_order_value,
-- Compuate average monthly spend
CASE WHEN months_as_customer = 0 THEN total_spending
     ELSE total_spending / months_as_customer
END AS avg_monthly_spend
FROM customer_aggregation;

/* 
Product Report

Purpose
	this report consolidates key product metrics and behaviours

Highlights
	1. gathers essential fields such as product name,category, subcategory and cost
	2. segments products by revenue to identify high-performers, mid-range or low-performers
	3. aggregates product-level metrics
		total orders
		total sales
		total quantity sold
		total customers(unique)
		lifespan
	4. calculates valuable KPIs
		recency(months since last sale)
		average order revenue(AOR)
		average monthly revenue
*/

WITH base AS
(
SELECT 
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	f.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON p.product_key=f.product_key
WHERE f.order_date IS NOT NULL
), product_aggregations AS
(
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_order_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customer,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT)/NULLIF(quantity,0)),1) AS average_selling_price
FROM base
GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)
SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_order_date,
	DATEDIFF(MONTH,last_order_date,GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales>50000 THEN 'High Performer'
		WHEN total_sales BETWEEN 50000 AND 10000 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customer,
	average_selling_price,
	-- avg order revenue
	CASE
		WHEN total_orders=0 THEN 0
		ELSE total_sales/total_orders
	END AS average_order_revenue,
	-- avg monthly revenue
	CASE
		WHEN lifespan=0 THEN total_sales
		ELSE total_sales/lifespan
	END AS average_monthly_revenue
FROM product_aggregations