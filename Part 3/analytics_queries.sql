-- Query 1: Monthly Sales Drill-Down Analysis
-- Scenario: "The CEO wants to see sales performance broken down by time periods."
-- Drill-down: Year -> Quarter -> Month
Output:
year	quarter	month_name	total_sales	total_quantity
2024	Q1	January	319032.00	41
2024	Q1	February	490378.00	32

Query:

SELECT 
    d.year,
    d.quarter,
    d.month_name,
    SUM(f.total_amount) as total_sales,
    SUM(f.quantity_sold) as total_quantity
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.year = 2024
GROUP BY d.year, d.quarter, d.month, d.month_name
ORDER BY d.year, d.month;

-- Query 2: Product Performance Analysis
-- Scenario: "Identify top products by revenue contribution percentage."
-- Calculation: (Product Revenue / Total Revenue) * 100
Output:
product_name	category	units_sold	revenue	revenue_percentage
MacBook Pro	Electronics	2	240000.00	29.65%
iPhone 13	Electronics	3	209997.00	25.94%
Samsung Galaxy S21	Electronics	3	137997.00	17.05%
OnePlus Nord	Electronics	2	56000.00	6.92%
HP Laptop	Electronics	1	52999.00	6.55%
Dell Monitor	Electronics	2	25998.00	3.21%
Levis Jeans	Fashion	5	14995.00	1.85%
Nike Running Shoes	Fashion	4	13996.00	1.73%
Woodland Shoes	Fashion	2	10998.00	1.36%
Organic Honey	Groceries	21	9450.00	1.17%

Query:

WITH ProductStats AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.quantity_sold) as units_sold,
        SUM(f.total_amount) as revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_key = p.product_key
    GROUP BY p.product_key, p.product_name, p.category
)
SELECT 
    product_name,
    category,
    units_sold,
    revenue,
    CONCAT(ROUND((revenue / SUM(revenue) OVER ()) * 100, 2), '%') as revenue_percentage
FROM ProductStats
ORDER BY revenue DESC
LIMIT 10;

-- Query 3: Customer Segmentation Analysis
-- Scenario: "Segment customers into High/Medium/Low Value based on spending."
-- High: >50k, Medium: 20k-50k, Low: <20k
Output: 
customer_segment	customer_count	total_revenue	avg_revenue_per_customer
High Value	6	695975.00	115995.83
Medium Value	2	81245.00	40622.50
Low Value	4	32190.00	8047.50

Query:

WITH CustomerSpending AS (
    SELECT 
        c.customer_name,
        SUM(f.total_amount) as total_spent
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_key = c.customer_key
    GROUP BY c.customer_key, c.customer_name
),
Segments AS (
    SELECT 
        customer_name,
        total_spent,
        CASE 
            WHEN total_spent > 50000 THEN 'High Value'
            WHEN total_spent BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END as customer_segment
    FROM CustomerSpending
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    SUM(total_spent) as total_revenue,
    ROUND(AVG(total_spent), 2) as avg_revenue_per_customer
FROM Segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;