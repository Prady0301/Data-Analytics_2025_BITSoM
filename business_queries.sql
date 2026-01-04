-- Query 1: Customer Purchase History
-- Business Question: "Generate a detailed report showing each customer's name, email, 
total number of orders placed, and total amount spent. Include only customers who have 
placed at least 2 orders and spent more than ₹5,000. Order by total amount spent 
in descending order."

-- Expected Output:

customer_name	email	total_orders	total_spent
Arjun Rao	arjun.rao@gmail.com	10	414990.00
Divya Menon	divya.menon@gmail.com	5	349995.00
Karthik Nair	karthik.nair@yahoo.com	10	287990.00
Priya Patel	priya.patel@yahoo.com	10	259985.00
Rahul Sharma	rahul.sharma@gmail.com	5	229995.00
Rajesh Kumar	rajesh.kumar@gmail.com	10	182975.00
Lakshmi Krishnan	unknown_C012	3	118997.00
Amit Kumar	unknown_C003	4	114992.00
Anjali Mehta	anjali.mehta@gmail.com	10	87990.00
Swati Desai	swati.desai@gmail.com	6	73494.00
Neha Shah	neha.shah@gmail.com	10	27980.00
Suresh Patel	suresh.patel@outlook.com	10	26740.00
Manish Joshi	manish.joshi@yahoo.com	10	24285.00
Deepa Gupta	deepa.gupta@gmail.com	5	22475.00
Ravi Verma	unknown_C007	4	21992.00
Sneha Reddy	sneha.reddy@gmail.com	5	16250.00
Arun Pillai	arun.pillai@outlook.com	5	14990.00
Kavya Reddy	unknown_C018	4	11394.00
Vikram Singh	vikram.singh@outlook.com	5	9750.00
Pooja Iyer	pooja.iyer@gmail.com	5	9000.00

-- Actual Query:
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING COUNT(o.order_id) >= 2 AND SUM(o.total_amount) > 5000
ORDER BY total_spent DESC;

-- Query 2: Product Sales Analysis
-- Business Question: "For each product category, show the category name, 
number of different products sold, total quantity sold, and total revenue generated. 
Only include categories that have generated more than ₹10,000 in revenue. 
Order by total revenue descending."
-- Expected Output:

category	num_products_sold	total_quantity_sold	total_revenue
Electronics	9	86	2057914.00
Fashion	7	62	167338.00
Groceries	4	160	87005.00

-- Actual Query:
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS num_products_sold,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.subtotal) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
HAVING SUM(oi.subtotal) > 10000
ORDER BY total_revenue DESC;

-- Query 3: Monthly Sales Trend
-- Business Question: "Show monthly sales trends for the year 2024. For each month, 
display the month name, total number of orders, total revenue, and the running total 
of revenue (cumulative revenue from January to that month)."

-- Expected Output:

month_name	total_orders	monthly_revenue	cumulative_revenue
January	34	476519.00	476519.00
February	35	691282.00	1167801.00
March	44	716202.00	1884003.00
April	22	414258.00	2298261.00
December	2	13996.00	2312257.00

-- Actual Query:
SELECT 
    DATE_FORMAT(order_date, '%M') AS month_name,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS monthly_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY MIN(order_date)) AS cumulative_revenue
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY MONTH(order_date), DATE_FORMAT(order_date, '%M')
ORDER BY MONTH(order_date);