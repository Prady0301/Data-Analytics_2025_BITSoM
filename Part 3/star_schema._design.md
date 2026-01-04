# Star Schema Design Documentation

## Section 1: Schema Overview

The Data Warehouse is designed as a **Star Schema** to optimize query performance for historical sales analysis.

**FACT TABLE: fact_sales**
* **Grain:** One row per individual line item in a sales transaction.
* **Business Process:** Recorded when a sales transaction is completed in the operational system.
* **Measures (Numeric Facts):**
    * `quantity_sold`: Number of units.
    * `unit_price`: Price per unit at the moment of sale.
    * `total_amount`: Final revenue from this line item (`quantity` × `unit_price`).
* **Foreign Keys:**
    * `date_key` → Links to `dim_date`
    * `product_key` → Links to `dim_product`
    * `customer_key` → Links to `dim_customer`

**DIMENSION TABLES**

**1. dim_date**
* **Purpose:** Enables time-based roll-ups (Daily → Monthly → Quarterly → Yearly).
* **Attributes:**
    * `date_key` (PK): Integer representation (e.g., `20240115`).
    * `full_date`: Date format (`2024-01-15`).
    * `month_name`, `quarter`, `year`: For grouping.
    * `is_weekend`: Boolean flag to analyze weekend vs. weekday performance.

**2. dim_product**
* **Purpose:** Stores catalog details. Uses Surrogate Keys to handle history.
* **Attributes:**
    * `product_key` (PK): Auto-incrementing integer (Surrogate Key).
    * `product_id`: The original operational ID (e.g., '1').
    * `product_name`, `category`, `subcategory`: For hierarchical grouping.

**3. dim_customer**
* **Purpose:** Stores customer demographics.
* **Attributes:**
    * `customer_key` (PK): Auto-incrementing integer (Surrogate Key).
    * `customer_id`: The original operational ID (e.g., '1').
    * `city`, `state`, `segment`: For geographic and behavioral analysis.

---

## Section 2: Design Decisions

**1. Granularity (Line-Item Level)**

I chose the finest grain (line-item) rather than aggregating by order header.
* **Justification:** Storing individual line items allows us to slice revenue by **Product Category** or **Brand**. If we only stored the "Order Total," we would lose visibility into *which* specific products contributed to that total.

**2. Surrogate Keys**
We use integer Surrogate Keys (e.g., `product_key = 1`) instead of the natural Operational Keys (e.g., `product_id = 'P001'`).
* **Performance:** Joining on Integers is faster than joining on Strings.
* **History:** If 'P001' is renamed or deleted in the source system, our Data Warehouse history remains intact. It also allows us to implement "Slowly Changing Dimensions" (SCD) in the future if we want to track price changes over time.

****3. Support for Drill-Down and Roll-Up** 
The schema is explicitly designed with Dimensional Hierarchies to support OLAP operations:

Drill-Down (General → Specific):

Time Hierarchy: The dim_date table contains attributes year, quarter, month, and full_date. An analyst can view total sales by Year and then "drill down" to see how that year breaks down into Quarters, then Months, and finally specific Days.

Product Hierarchy: The dim_product table contains category, subcategory, and product_name. This allows drilling down from "Electronics" (Category) to "Smartphones" (Subcategory) to "Samsung Galaxy S21" (Product).

Roll-Up (Specific → General):

Because the Fact Table stores data at the lowest grain (individual line item), we can use GROUP BY functions to "roll up" this granular data to any level.

Example: We can roll up daily sales of individual products (product_key + date_key) to calculate the Total Revenue for the "Fashion" category in "Q1 2024" by simply grouping by dim_product.category and dim_date.quarter.

Visual Example for your understanding
Roll-Up: "Show me total sales for 2024." (Result: ₹1,000,000)

The database sums up thousands of individual line items.

Drill-Down: "Why was Q1 lower than Q2? Show me Q1 sales by Month." (Result: Jan: ₹100k, Feb: ₹100k, Mar: ₹50k)

The database breaks that total down using the month column in dim_date.

## Section 3: Sample Data Flow

**Source Transaction (Operational DB)**
* **Order:** T100 | **Date:** 2024-01-15 | **Cust:** 1 (Rahul)
* **Item:** 1 (Samsung Phone) | **Qty:** 1 | **Price:** 45000

**Becomes in Data Warehouse:**

**1. Dimensions are looked up/created:**
* `dim_date`: Returns `20240115`
* `dim_customer`: Looks up '1' → Returns `customer_key: 5`
* `dim_product`: Looks up '1' → Returns `product_key: 10`

**2. Fact Row is Inserted:**
```json
{
  "sale_key": (Auto),
  "date_key": 20240115,
  "customer_key": 5,
  "product_key": 10,
  "quantity_sold": 1,
  "total_amount": 45000
}