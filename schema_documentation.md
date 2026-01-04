1. Entity-Relationship Description
The FlexiMart database consists of four normalized entities designed to handle e-commerce transactions efficiently.

**ENTITY: customers**

Purpose: Stores persistent information about registered customers.

Attributes:

customer_id (PK): Unique identifier (Format: '1', '2').

first_name, last_name: Customer's personal name.

email: Unique contact email (used for login/contact).

phone: Standardized contact number (+91-XXXXXXXXXX).

city: Location for demographics.

registration_date: Date of account creation.

Relationships:

1:M with orders: A single customer can place multiple orders over time.

**ENTITY: products**

Purpose: Maintains the current catalog of items available for sale.

Attributes:

product_id (PK): Unique SKU identifier (Format: '1', '2').

product_name: Descriptive name of the item.

category: Classification (e.g., Electronics, Fashion).

price: Current list price per unit.

stock_quantity: Current available inventory.

Relationships:

1:M with order_items: A product record can be referenced in many different order line items.

**ENTITY: orders**

Purpose: Represents the "header" of a sales transaction (Who, When, Status).

Attributes:

order_id (PK): Unique auto-incrementing integer for the transaction.

customer_id (FK): Links to the customers table.

order_date: The date the transaction occurred.

total_amount: The final sum of the transaction.

status: Order state (Completed, Cancelled).

Relationships:

M:1 with customers: Belongs to one specific customer.

1:M with order_items: Contains one or more specific line items.

**ENTITY: order_items**

Purpose: Represents the "detail" lines of a transaction (What exactly was bought).

Attributes:

order_item_id (PK): Unique identifier for the line item.

order_id (FK): Links to the parent order.

product_id (FK): Links to the specific product sold.

quantity: Number of units purchased in this line.

unit_price: The price at the moment of sale (preserves history if catalog price changes).

subtotal: Calculated as quantity * unit_price.

Relationships:

M:1 with orders: Part of a larger order.

M:1 with products: References a specific catalog item.

2. Normalization Explanation
The database design adheres to the Third Normal Form (3NF) to ensure data integrity and reduce redundancy.

# a. First Normal Form (1NF): Atomicity

All columns contain atomic values. We do not store a comma-separated list of products in the orders table (e.g., "P001, P002"). Instead, we broke this out into the order_items table, where each row represents a single product in an order.

Each record is unique and has a primary key.

# b. Second Normal Form (2NF): No Partial Dependencies

All non-key attributes depend on the entire primary key.

In order_items (where the logical key is the composite of Order+Product), attributes like quantity apply to the specific combination of that order and that product, not just one of them.

We separated products into their own table so that product details (Name, Category) generally depend only on product_id, not on the order they were part of.

# c. Third Normal Form (3NF): No Transitive Dependencies

Goal: Non-key attributes must depend only on the primary key, not on other non-key attributes.

Implementation: * Customer City depends only on customer_id. If we stored customer_city in the orders table, it would depend on customer_id (which is a foreign key in that table), creating a transitive dependency. By moving it to the customers table, we ensure that if a customer moves, we update their address in one place, avoiding Update Anomalies.

Product Category depends only on product_id. We do not store "Category" in the order_items table. This avoids Insertion Anomalies (we can create a new product/category without waiting for it to be sold) and Deletion Anomalies (deleting the only order for a product doesn't delete the product's record from our system).

3. Sample Data Representation

**Table: customers**

customer_id,first_name,last_name,email,phone,city,registration_date
1,Rahul,Sharma,rahul.sharma@gmail.com,+91-9876543210,Bangalore,2023-01-15
2,Priya,Patel,priya.patel@yahoo.com,+91-9988776655,Mumbai,2023-02-20
3,Amit,Kumar,unknown_003,+91-9765432109,Delhi,2023-03-10

**Table: Products**
product_id,product_name,category,price,stock_quantity
1,Samsung Galaxy S21,Electronics,45999.00,150
2,Nike Running Shoes,Fashion,3499.00,80
3,Apple MacBook Pro,Electronics,120000.00,45

**Table: Orders**
order_id,customer_id,order_date,total_amount,status
1,001,2024-01-15,45999.00,Completed
2,002,2024-01-16,6998.00,Completed
3,003,2024-01-15,52999.00,Completed

**Table: Order_items**
order_item_id,order_id,product_id,quantity,unit_price,subtotal
1,1,P001,1,45999.00,45999.00
2,2,P004,2,2999.00,5998.00
3,3,P007,1,52999.00,52999.00