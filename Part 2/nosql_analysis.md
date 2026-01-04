# NoSQL Analysis Report

## Section A: Limitations of RDBMS
Ques: Explain why the current relational database would struggle with:
1. Products having different attributes (e.g., laptops have RAM/processor, shoes have size/color)
2. Frequent schema changes when adding new product types
3. Storing customer reviews as nested data

Solution:
The current relational database (MySQL) faces significant challenges when scaling FlexiMart's diverse product catalog:
1.  **Rigid Schema & Sparse Data:** In an RDBMS, every row in a table must adhere to the same column structure. However, "Laptops" require attributes like `RAM` and `Processor`, while "Clothing" requires `Size` and `Material`. To store both in one `products` table, we would need to create columns for all possible attributes, resulting in a table filled with `NULL` values (sparse matrix), which is inefficient.
2.  **Complex Schema Evolution:** Adding a new product line (e.g., "Books" with `ISBN`) requires `ALTER TABLE` commands to add columns. In a production environment with millions of records, this operation can lock the database, causing downtime.
3.  **Join overhead for Reviews:** Currently, fetching a product along with its reviews requires a `JOIN` operation between the `products` and `reviews` tables. As traffic grows, these joins become computationally expensive and slow down page load times.

## Section B: NoSQL Benefits (MongoDB)
Question: Explain how MongoDB solves these problems using:
1. Flexible schema (document structure)
2. Embedded documents (reviews within products)
3. Horizontal scalabilityMongoDB addresses these issues through its flexible document model:

Solution:
1.  **Dynamic Schema:** MongoDB uses BSON (Binary JSON) documents. We can store a Laptop document with a `specs` object containing technical details, and a Shirt document with an `attributes` object containing fabric details, all within the same `products` collection. No schema migration is required.
2.  **Embedded Data Model:** By embedding the `reviews` array directly inside the product document, we can retrieve the product details and all user reviews in a single read operation. This significantly improves read performance for product display pages.
3.  **Horizontal Scalability:** MongoDB is designed to scale out. As the catalog grows to millions of items, we can use **Sharding** to distribute the data across multiple servers automatically, whereas scaling MySQL usually involves complex manual partitioning or expensive vertical scaling (buying bigger servers).

## Section C: Trade-offs
Question: What are two disadvantages of using MongoDB instead of MySQL for this product catalog?

Solution:
While MongoDB offers flexibility, there are trade-offs compared to MySQL:

1.  **Data Redundancy:** In the embedded model, if we store user details (like `username`) inside the review object within a product, and that user changes their name, we must update it in every product document they have reviewed. In MySQL, we would only update the `users` table once.
2.  **Transaction Complexity:** While MongoDB supports multi-document transactions, they are more resource-intensive and complex to implement than SQL's ACID transactions. For strict inventory management where consistency is critical (e.g., ensuring stock doesn't go below zero during concurrent purchases), MySQL's rigid consistency is often safer.