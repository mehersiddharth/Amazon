import sqlite3
import pandas as pd
import os

# ----------------------------------
# Configuration
# ----------------------------------
DB_NAME = "ecommerce.db"
DATA_FOLDER = "data"

# ----------------------------------
# Helper: normalize CSV column names
# ----------------------------------
def clean_columns(df):
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
    )
    return df


# ----------------------------------
# Connect to SQLite
# ----------------------------------
conn = sqlite3.connect(DB_NAME)
cursor = conn.cursor()

# ----------------------------------
# Drop & Create tables
# ----------------------------------
cursor.executescript("""
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS shippings;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS category;

CREATE TABLE category (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT
);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    state TEXT
);

CREATE TABLE sellers (
    seller_id INTEGER PRIMARY KEY,
    seller_name TEXT,
    origin TEXT
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    price REAL,
    cogs REAL,
    category_id INTEGER,
    FOREIGN KEY(category_id) REFERENCES category(category_id)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE,
    customer_id INTEGER,
    seller_id INTEGER,
    order_status TEXT,
    FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    price_per_unit REAL,
    FOREIGN KEY(order_id) REFERENCES orders(order_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    payment_date DATE,
    payment_status TEXT,
    FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

CREATE TABLE shippings (
    shipping_id INTEGER PRIMARY KEY,
    order_id INTEGER,
    shipping_date DATE,
    return_date DATE,
    shipping_providers TEXT,
    delivery_status TEXT,
    FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

CREATE TABLE inventory (
    inventory_id INTEGER PRIMARY KEY,
    product_id INTEGER,
    stock INTEGER,
    warehouse_id INTEGER,
    last_stock_date DATE,
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);
""")

conn.commit()

# ----------------------------------
# Load CSV files
# ----------------------------------
tables = [
    "category",
    "customers",
    "sellers",
    "products",
    "orders",
    "order_items",
    "payments",
    "shipping",
    "inventory"
]

for table in tables:
    csv_path = os.path.join(DATA_FOLDER, f"{table}.csv")

    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Missing file: {csv_path}")

    df = pd.read_csv(csv_path)
    df = clean_columns(df)

    df.to_sql(table, conn, if_exists="append", index=False)
    print(f"Loaded {table}.csv")

conn.close()

print("\n✅ All CSV files loaded successfully into ecommerce.db")
