import json
import pymongo
from datetime import datetime

# ==========================================
# CONFIGURATION
# ==========================================
# Connect to local MongoDB
# Ensure MongoDB is running on localhost:27017
client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["Fleximart"]
collection = db["Products_catalog"]

def run_operations():
    try:
        print("--- STARTING MONGODB OPERATIONS ---")

        # ==========================================
        # Operation 1: Load Data
        # ==========================================
        print("\n>>> Operation 1: Loading Data...")
        
        # Reset collection to ensure clean slate
        collection.drop()
        
        # Load data from JSON file
        try:
            with open('/Users/shiv/Documents/python/GitHub/Data-Analytics_2025_BITSoM/Part 2/products_catalog.json', 'r') as file:
                data = json.load(file)
                if isinstance(data, list) and len(data) > 0:
                    collection.insert_many(data)
                    print(f"Successfully loaded {len(data)} products.")
                else:
                    print("Error: JSON file is empty or not a list.")
        except FileNotFoundError:
            print("Error: 'products_catalog.json' not found in current directory.")
            return

        # ==========================================
        # Operation 2: Basic Query
        # ==========================================
        # Requirement: Find all "Electronics" priced less than 50,000.
        # Return only: name, price, stock
        print("\n>>> Operation 2: Electronics under 50k")
        
        query = {"category": "Electronics", "price": {"$lt": 50000}}
        projection = {"_id": 0, "name": 1, "price": 1, "stock": 1}
        
        results = collection.find(query, projection)
        
        for doc in results:
            print(doc)

        # ==========================================
        # Operation 3: Review Analysis
        # ==========================================
        # Requirement: Find products with average rating >= 4.0
        print("\n>>> Operation 3: Products with Avg Rating >= 4.0")
        
        pipeline_rating = [
            {"$unwind": "$reviews"},
            {
                "$group": {
                    "_id": "$product_id",
                    "name": {"$first": "$name"},
                    "avg_rating": {"$avg": "$reviews.rating"}
                }
            },
            {"$match": {"avg_rating": {"$gte": 4.0}}},
            # Optional: Round the rating for cleaner display
            {"$project": {"name": 1, "avg_rating": {"$round": ["$avg_rating", 1]}}}
        ]
        
        results = collection.aggregate(pipeline_rating)
        
        for doc in results:
            print(doc)

        # ==========================================
        # Operation 4: Update Operation
        # ==========================================
        # Requirement: Add a new review to product "ELEC001"
        print("\n>>> Operation 4: Adding new review to ELEC001")
        
        new_review = {
            "user_id": "U999",
            "username": "VerifiedBuyer",
            "rating": 4,
            "comment": "Great battery life!",
            "date": datetime.now().strftime("%Y-%m-%d")
        }
        
        update_result = collection.update_one(
            {"product_id": "ELEC001"},
            {"$push": {"reviews": new_review}}
        )
        
        if update_result.modified_count > 0:
            print("Update successful.")
            # Verify the update
            updated_doc = collection.find_one(
                {"product_id": "ELEC001"},
                {"name": 1, "reviews": {"$slice": -1}, "_id": 0} # Fetch last review
            )
            print("Verification (Last Review):", updated_doc)
        else:
            print("Update failed: Product not found.")

        # ==========================================
        # Operation 5: Complex Aggregation
        # ==========================================
        # Requirement: Calculate average price by category
        # Return: category, avg_price, product_count (Sorted by price descending)
        print("\n>>> Operation 5: Average Price by Category")
        
        pipeline_category = [
            {
                "$group": {
                    "_id": "$category",
                    "avg_price": {"$avg": "$price"},
                    "product_count": {"$sum": 1}
                }
            },
            {"$sort": {"avg_price": -1}},
            {
                "$project": {
                    "category": "$_id",
                    "avg_price": {"$round": ["$avg_price", 2]},
                    "product_count": 1,
                    "_id": 0
                }
            }
        ]
        
        results = collection.aggregate(pipeline_category)
        
        for doc in results:
            print(doc)

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        client.close()
        print("\n--- OPERATIONS COMPLETED ---")

if __name__ == "__main__":
    run_operations()