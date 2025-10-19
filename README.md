# SQL Data Analyst Portfolio Project

## Project Overview
This project demonstrates advanced data analytics using SQL techniques. It covers real-world business questions by analyzing sales, customers, and product data through diverse SQL queries. The project simulates a professional data analyst's workflow in creating reports and insights from raw data.

### The key objectives of this project are to:

* Analyze changes over time to identify trends and seasonality

* Perform cumulative analysis to track business growth

* Conduct performance comparisons against targets like averages and previous periods

* Segment data for customer and product insights

* Build comprehensive customer and product reports for stakeholders

**You will learn advanced SQL concepts including window functions, CTEs, subqueries, aggregate functions, and date/time manipulations.**

## Data Description
The project uses a sample dataset structured in a data warehouse style with three main tables:

* Customer: Contains customer details and demographics.

* Product: Contains product attributes like product name and category.

* Sales: Fact table containing sales transactions with keys to customer and product, sales amount, order dates, and quantities.

## Project Structure and Features
1. Data Setup
Create the database and schema using provided SQL scripts.

Import CSV files or restore the database backup to populate tables.

Establish relationships among tables to enable complex SQL queries.

2. Analytical Tasks
Change Over Time Analysis
Calculate total sales, customers, and quantity aggregated by different time grains (year, month, day).

Identify trends and seasonality by comparing metrics across time periods.

**Cumulative Analysis**

Implement running totals and moving averages using window functions.

Analyze progressive business growth over specified periods.

**Performance Analysis**

Compare current period sales with averages and previous periods using window functions such as AVG() and LAG().

Flag performance as above average, below average, increasing, or decreasing.

**Part-to-Whole Analysis**

Calculate the contribution percentage of each product category or customer segment towards overall sales.

Use window functions to compute total sales across all categories for proportion analysis.

**Data Segmentation**

Segment customers and products for targeted insights (covered briefly).

**Reporting**

Build detailed customer and product reports to present actionable business insights using complex SQL queries.

**Tools & Technologies**

Microsoft SQL Server (Express or other versions)

SQL Server Management Studio (SSMS) or any SQL execution environment

### How to Run This Project
* Download the project files and SQL scripts from the provided materials.

* Create the database by running the init_database.sql script or restoring the backup database.

* Import the CSV files into respective tables if not using backup.

* Use the SQL scripts provided to perform the different analyses step-by-step.

* Review the results to understand business trends, performance, and segmentation.

## Learning Outcomes
* By completing this project, you will:

* Master advanced SQL techniques applicable to real business scenarios.

Gain practical skills for building robust data warehouse queries.

* Understand how to analyze, aggregate, and segment data efficiently.

* Be prepared to create impactful reports for stakeholders in a business context.

* Enhance your data analyst portfolio with a comprehensive SQL-based project.
