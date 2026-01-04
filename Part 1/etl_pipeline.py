
#FLeximart ETL Pipeline
# Description: Extracts, transforms, and loads customer, product, and sales data into a MySQL database.
#Author: Sivadutta Pradhan
import pandas as pd
import mysql.connector
from datetime import datetime
import re
# --- DATABASE CONFIGURATION ---
DB_CONFIG = {
    'user': 'root',
    'password': 'Prady@241164',
    'host': 'localhost',
    'database': 'Fleximart'
}

# --- GLOBAL METRICS STORE ---
metrics = {
    "customers": {"processed": 0, "duplicates": 0, "missing": 0, "loaded": 0},
    "products":  {"processed": 0, "duplicates": 0, "missing": 0, "loaded": 0},
    "sales":     {"processed": 0, "duplicates": 0, "missing": 0, "loaded": 0}
}
#Cleans phone numbers to standard format +91-XXXXXXXXXX
def clean_phone(phone):
    if pd.isna(phone): return None
    clean = re.sub(r'[^0-9]', '', str(phone))
    if len(clean) >= 10: return f"+91-{clean[-10:]}"
    return None
#cleans and standardizes date formats to YYYY-MM-DD
def parse_date(date_str):
    if pd.isna(date_str): return None
    date_str = str(date_str).strip()
    formats = ['%Y-%m-%d', '%d/%m/%Y', '%m-%d-%Y', '%d-%m-%Y']
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt).strftime('%Y-%m-%d')
        except ValueError:
            continue
    return None

def extract_transform_load():
    conn = None
    try:
        # --- 1. EXTRACT ---
        print("Extracting data...")
        df_cust = pd.read_csv('customers_raw.csv')
        df_prod = pd.read_csv('products_raw.csv')
        df_sales = pd.read_csv('sales_raw.csv')

        # Initialize "Processed" counts
        metrics["customers"]["processed"] = len(df_cust)
        metrics["products"]["processed"] = len(df_prod)
        metrics["sales"]["processed"] = len(df_sales)

        # --- 2. TRANSFORM ---
        
        # --- A. Customers ---
        # 1. Duplicates
        initial_c = len(df_cust)
        df_cust.drop_duplicates(subset=['customer_id'], inplace=True)
        metrics["customers"]["duplicates"] = initial_c - len(df_cust)
        
        # 2. Handle Missing Emails -> "Unknown" Strategy
        # Count them first
        missing_mask = df_cust['email'].isnull()
        metrics["customers"]["missing"] = missing_mask.sum()
        
        # Fill with unique unknown string: "unknown_C003"
        # We MUST append ID because the DB 'email' column is UNIQUE. 
        # If we just used "Unknown", only 1 customer would save.
        df_cust.loc[missing_mask, 'email'] = 'unknown_' + df_cust.loc[missing_mask, 'customer_id']
    

        # Clean fields
        df_cust['phone'] = df_cust['phone'].apply(clean_phone)
        df_cust['registration_date'] = df_cust['registration_date'].apply(parse_date)
        df_cust['db_id'] = df_cust['customer_id'].apply(lambda x: int(re.sub(r'\D', '', str(x))))
        
        metrics["customers"]["loaded"] = len(df_cust)

        # --- B. PRODUCTS ---
        # 1. Cleaning ID Fields
        df_prod['product_id'] = df_prod['product_id'].astype(str).str.strip()

        # 2. Deduplicate
        initial_p = len(df_prod)
        df_prod.drop_duplicates(subset=['product_id'], inplace=True)
        metrics["products"]["duplicates"] = initial_p - len(df_prod)

        # 3. Handle Missing Prices -> Fill with Median
        missing_price_mask = df_prod['price'].isnull()
        metrics["products"]["missing"] = missing_price_mask.sum()
        median_price = df_prod['price'].median()
        df_prod['price'] = df_prod['price'].fillna(median_price)
        
        # 4. Other Cleaning
        df_prod['stock_quantity'] = df_prod['stock_quantity'].fillna(0)
        df_prod['category'] = df_prod['category'].str.title().str.strip()
        df_prod['db_id'] = df_prod['product_id'].apply(lambda x: int(re.sub(r'\D', '', str(x))))

        metrics["products"]["loaded"] = len(df_prod)

        # --- C. Sales ---
        # 1. Duplicates (Transaction ID)
        initial_s = len(df_sales)
        df_sales['transaction_id'] = df_sales['transaction_id'].str.strip()
        df_sales.drop_duplicates(subset=['transaction_id'], inplace=True)
        metrics["sales"]["duplicates"] = initial_s - len(df_sales)

        # 2. Missing/Invalid Values
        before_missing_s = len(df_sales)
        
        # Parse dates first (needed for validity)
        df_sales['transaction_date'] = df_sales['transaction_date'].apply(parse_date)
        
        # Identify rows with Missing Date OR Missing Customer OR Missing Product
        invalid_mask = (
            df_sales['transaction_date'].isnull() | 
            df_sales['customer_id'].isnull() | 
            df_sales['product_id'].isnull()
        )
        df_sales = df_sales[~invalid_mask]
        
        metrics["sales"]["missing"] = before_missing_s - len(df_sales)

        # Filter for Referent Integrity (IDs must exist in cleaned tables)
        df_sales['cust_db_id'] = df_sales['customer_id'].apply(lambda x: int(re.sub(r'\D', '', str(x))))
        df_sales['prod_db_id'] = df_sales['product_id'].apply(lambda x: int(re.sub(r'\D', '', str(x))))
        
        valid_cust = set(df_cust['db_id'])
        valid_prod = set(df_prod['db_id'])
        
        # If ID not in valid sets, count as "Missing/Invalid" logic
        before_fk_filter = len(df_sales)
        df_sales = df_sales[
            df_sales['cust_db_id'].isin(valid_cust) & 
            df_sales['prod_db_id'].isin(valid_prod)
        ]
        metrics["sales"]["missing"] += (before_fk_filter - len(df_sales))

        metrics["sales"]["loaded"] = len(df_sales)

        # --- 3. LOAD ---
        print("Loading data to SQL...")
        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Load Customers
        for _, row in df_cust.iterrows():
            sql = "INSERT IGNORE INTO customers (customer_id, first_name, last_name, email, phone, city, registration_date) VALUES (%s, %s, %s, %s, %s, %s, %s)"
            cursor.execute(sql, (row['db_id'], row['first_name'], row['last_name'], row['email'], row['phone'], row['city'], row['registration_date']))

        # Load Products
        for _, row in df_prod.iterrows():
            sql = "INSERT IGNORE INTO products (product_id, product_name, category, price, stock_quantity) VALUES (%s, %s, %s, %s, %s)"
            cursor.execute(sql, (row['db_id'], row['product_name'], row['category'], row['price'], row['stock_quantity']))
        
        conn.commit()

        # Load Orders
        orders_group = df_sales.groupby('transaction_id').first().reset_index()
        order_map = {}

        for _, row in orders_group.iterrows():
            items = df_sales[df_sales['transaction_id'] == row['transaction_id']]
            total = (items['quantity'] * items['unit_price']).sum()
            sql = "INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES (%s, %s, %s, %s)"
            cursor.execute(sql, (row['cust_db_id'], row['transaction_date'], total, row['status']))
            order_map[row['transaction_id']] = cursor.lastrowid

        # Load Order Items
        for _, row in df_sales.iterrows():
            oid = order_map.get(row['transaction_id'])
            if oid:
                sub = row['quantity'] * row['unit_price']
                sql = "INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal) VALUES (%s, %s, %s, %s, %s)"
                cursor.execute(sql, (oid, row['prod_db_id'], row['quantity'], row['unit_price'], sub))

        conn.commit()
        print("Data Loaded.")

        # --- 4. GENERATE REPORT ---
        report_content = (
            "DATA QUALITY REPORT\n"
            "===================\n\n"
            "FILE: customers_raw.csv\n"
            f"Number of records processed per file: {metrics['customers']['processed']}\n"
            f"Number of duplicates removed:         {metrics['customers']['duplicates']}\n"
            f"Number of missing values handled:     {metrics['customers']['missing']}\n"
            f"Number of records loaded successfully:{metrics['customers']['loaded']}\n\n"
            
            "FILE: products_raw.csv\n"
            f"Number of records processed per file: {metrics['products']['processed']}\n"
            f"Number of duplicates removed:         {metrics['products']['duplicates']}\n"
            f"Number of missing values handled:     {metrics['products']['missing']}\n"
            f"Number of records loaded successfully:{metrics['products']['loaded']}\n\n"
            
            "FILE: sales_raw.csv\n"
            f"Number of records processed per file: {metrics['sales']['processed']}\n"
            f"Number of duplicates removed:         {metrics['sales']['duplicates']}\n"
            f"Number of missing values handled:     {metrics['sales']['missing']}\n"
            f"Number of records loaded successfully:{metrics['sales']['loaded']}\n"
        )

        with open('data_quality_report.txt', 'w') as f:
            f.write(report_content)
        
        print("Report 'data_quality_report.txt' generated successfully.")

    except Exception as e:
        print(f"ETL Error: {e}")
    finally:
        if conn and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    extract_transform_load()