USE fleximart_dw;

-- =============================================
-- 1. Populate Date Dimension (Automated Generator)
-- =============================================
-- Generates dates from Jan 1, 2024 to Feb 29, 2024 (60 days)
INSERT INTO dim_date (date_key, full_date, day_of_week, day_of_month, month, month_name, quarter, year, is_weekend)
WITH RECURSIVE date_cte AS (
    SELECT DATE('2024-01-01') AS full_date
    UNION ALL
    SELECT DATE_ADD(full_date, INTERVAL 1 DAY)
    FROM date_cte
    WHERE full_date < '2024-02-29'
)
SELECT 
    DATE_FORMAT(full_date, '%Y%m%d') AS date_key,
    full_date,
    DAYNAME(full_date) AS day_of_week,
    DAY(full_date) AS day_of_month,
    MONTH(full_date) AS month,
    MONTHNAME(full_date) AS month_name,
    CONCAT('Q', QUARTER(full_date)) AS quarter,
    YEAR(full_date) AS year,
    CASE WHEN DAYOFWEEK(full_date) IN (1,7) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_cte;


-- =============================================
-- 2. Populate Product Dimension (15 Products, 3 Categories)
-- =============================================
-- Note: 'product_key' is Auto-Increment (1, 2, 3...)
INSERT INTO dim_product (product_id, product_name, category, subcategory, unit_price) VALUES
('1', 'Samsung Galaxy S21', 'Electronics', 'Smartphone', 45999.00),
('2', 'Nike Running Shoes', 'Fashion', 'Footwear', 3499.00),
('3', 'MacBook Pro', 'Electronics', 'Laptop', 120000.00),
('4', 'Levis Jeans', 'Fashion', 'Clothing', 2999.00),
('5', 'Sony Headphones', 'Electronics', 'Audio', 1999.00),
('6', 'Organic Almonds', 'Groceries', 'Dry Fruits', 899.00),
('7', 'HP Laptop', 'Electronics', 'Laptop', 52999.00),
('8', 'Adidas T-Shirt', 'Fashion', 'Clothing', 1299.00),
('9', 'Basmati Rice 5kg', 'Groceries', 'Staples', 650.00),
('10', 'OnePlus Nord', 'Electronics', 'Smartphone', 28000.00),
('11', 'Puma Sneakers', 'Fashion', 'Footwear', 4599.00),
('12', 'Dell Monitor', 'Electronics', 'Peripherals', 12999.00),
('13', 'Woodland Shoes', 'Fashion', 'Footwear', 5499.00),
('14', 'iPhone 13', 'Electronics', 'Smartphone', 69999.00),
('15', 'Organic Honey', 'Groceries', 'Condiments', 450.00);

-- =============================================
-- 3. Populate Customer Dimension (12 Customers, 4 Cities)
-- =============================================
-- Note: 'customer_key' is Auto-Increment (1, 2, 3...)
INSERT INTO dim_customer (customer_id, customer_name, city, state, customer_segment) VALUES
('1', 'Rahul Sharma', 'Bangalore', 'Karnataka', 'High Value'),
('2', 'Priya Patel', 'Mumbai', 'Maharashtra', 'Medium Value'),
('3', 'Amit Kumar', 'Delhi', 'Delhi', 'Low Value'),
('4', 'Sneha Reddy', 'Hyderabad', 'Telangana', 'Medium Value'),
('5', 'Vikram Singh', 'Chennai', 'Tamil Nadu', 'High Value'),
('6', 'Anjali Mehta', 'Bangalore', 'Karnataka', 'Medium Value'),
('7', 'Ravi Verma', 'Pune', 'Maharashtra', 'Low Value'),
('8', 'Pooja Iyer', 'Bangalore', 'Karnataka', 'Medium Value'),
('9', 'Karthik Nair', 'Kochi', 'Kerala', 'High Value'),
('10', 'Deepa Gupta', 'Delhi', 'Delhi', 'Low Value'),
('11', 'Arjun Rao', 'Hyderabad', 'Telangana', 'Medium Value'),
('12', 'Lakshmi K', 'Chennai', 'Tamil Nadu', 'Medium Value');


-- =============================================
-- 4. Populate Fact Sales (40 Transactions)
-- =============================================
-- IMPORTANT: 'product_key' and 'customer_key' here refer to the Auto-Increment IDs (1-15, 1-12) generated above.
-- Example: product_key=1 is Samsung S21 (P001), customer_key=1 is Rahul (C001)

INSERT INTO fact_sales (date_key, product_key, customer_key, quantity_sold, unit_price, total_amount) VALUES
-- Batch 1: Early January (Weekdays)
(20240115, 1, 1, 1, 45999.00, 45999.00),  -- Rahul buys Phone
(20240115, 9, 3, 2, 650.00, 1300.00),     -- Amit buys Rice
(20240116, 8, 4, 1, 1299.00, 1299.00),    -- Sneha buys T-Shirt
(20240117, 10, 6, 1, 28000.00, 28000.00), -- Anjali buys OnePlus
(20240118, 15, 7, 4, 450.00, 1800.00),    -- Ravi buys Honey
(20240119, 12, 1, 1, 12999.00, 12999.00), -- Rahul buys Monitor

-- Batch 2: Weekend Shopping Spree (Jan 20-21)
(20240120, 2, 1, 1, 3499.00, 3499.00),    -- Rahul buys Shoes
(20240120, 6, 2, 3, 899.00, 2697.00),     -- Priya buys Almonds
(20240120, 9, 2, 5, 650.00, 3250.00),     -- Priya buys 5 Rice (Bulk)
(20240121, 3, 5, 1, 120000.00, 120000.00),-- Vikram buys MacBook (High Value)
(20240121, 5, 5, 2, 1999.00, 3998.00),    -- Vikram buys Headphones
(20240121, 6, 5, 4, 899.00, 3596.00),     -- Vikram buys 4 Almonds

-- Batch 3: Late January (Republic Day Sale Weekend)
(20240127, 14, 9, 1, 69999.00, 69999.00), -- Karthik buys iPhone
(20240127, 4, 9, 2, 2999.00, 5998.00),    -- Karthik buys Jeans
(20240127, 15, 9, 10, 450.00, 4500.00),   -- Karthik buys 10 Honey (Bulk)
(20240128, 11, 8, 1, 4599.00, 4599.00),   -- Pooja buys Puma Shoes
(20240128, 13, 11, 1, 5499.00, 5499.00),  -- Arjun buys Woodland Shoes

-- Batch 4: Early February (Groceries & Small Items)
(20240201, 6, 10, 2, 899.00, 1798.00),    -- Deepa buys Almonds
(20240201, 2, 11, 1, 3499.00, 3499.00),   -- Arjun buys Nike
(20240202, 9, 10, 1, 650.00, 650.00),     -- Deepa buys Rice
(20240202, 3, 1, 1, 120000.00, 120000.00),-- Rahul buys MacBook
(20240203, 5, 2, 1, 1999.00, 1999.00),    -- Priya buys Headphones
(20240204, 8, 3, 1, 1299.00, 1299.00),    -- Amit buys T-Shirt
(20240205, 15, 3, 2, 450.00, 900.00),     -- Amit buys Honey
(20240205, 10, 4, 1, 28000.00, 28000.00), -- Sneha buys OnePlus
(20240206, 2, 4, 1, 3499.00, 3499.00),    -- Sneha buys Nike
(20240206, 11, 5, 1, 4599.00, 4599.00),   -- Vikram buys Puma
(20240207, 12, 6, 1, 12999.00, 12999.00), -- Anjali buys Monitor
(20240208, 5, 12, 1, 1999.00, 1999.00),   -- Lakshmi buys Headphones
(20240208, 13, 7, 1, 5499.00, 5499.00),   -- Ravi buys Woodland
(20240209, 14, 8, 1, 69999.00, 69999.00), -- Pooja buys iPhone

-- Batch 5: Mid February (High Value Weekend)
(20240210, 7, 5, 1, 52999.00, 52999.00),  -- Vikram buys HP Laptop
(20240210, 1, 2, 1, 45999.00, 45999.00),  -- Priya buys Samsung
(20240210, 15, 9, 5, 450.00, 2250.00),    -- Karthik buys Honey
(20240211, 14, 6, 1, 69999.00, 69999.00), -- Anjali buys iPhone
(20240211, 1, 10, 1, 45999.00, 45999.00), -- Deepa buys Samsung

-- Batch 6: Late Feb Mixed
(20240212, 8, 7, 3, 1299.00, 3897.00),    -- Ravi buys 3 T-Shirts
(20240212, 2, 11, 1, 3499.00, 3499.00),   -- Arjun buys Nike
(20240213, 4, 1, 2, 2999.00, 5998.00),    -- Rahul buys 2 Jeans
(20240213, 4, 12, 1, 2999.00, 2999.00);   -- Lakshmi buys Jeans