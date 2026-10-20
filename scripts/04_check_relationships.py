
from pathlib import Path
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "data" / "raw"

def load(name):
    return pd.read_csv(RAW_DIR / name, low_memory=False)

customers = load("olist_customers_dataset.csv")
orders = load("olist_orders_dataset.csv")
items = load("olist_order_items_dataset.csv")
payments = load("olist_order_payments_dataset.csv")
reviews = load("olist_order_reviews_dataset.csv")
products = load("olist_products_dataset.csv")
sellers = load("olist_sellers_dataset.csv")

def check_unique(df, column, table):
    duplicates = df[column].duplicated().sum()
    print(
        f"{table}.{column}: "
        f"{'PASS' if duplicates == 0 else 'CHECK'} "
        f"| duplicate keys = {duplicates:,}"
    )

def check_orphans(child, child_key, parent, parent_key, label):
    missing = (~child[child_key].isin(parent[parent_key])).sum()
    print(f"{label}: unmatched rows = {missing:,}")

print("\nPRIMARY KEY CANDIDATE CHECKS")
print("=" * 65)

check_unique(customers, "customer_id", "customers")
check_unique(orders, "order_id", "orders")
check_unique(products, "product_id", "products")
check_unique(sellers, "seller_id", "sellers")

print("\nRELATIONSHIP CHECKS")
print("=" * 65)

check_orphans(
    orders, "customer_id",
    customers, "customer_id",
    "Orders -> Customers"
)

check_orphans(
    items, "order_id",
    orders, "order_id",
    "Order items -> Orders"
)

check_orphans(
    items, "product_id",
    products, "product_id",
    "Order items -> Products"
)

check_orphans(
    items, "seller_id",
    sellers, "seller_id",
    "Order items -> Sellers"
)

check_orphans(
    payments, "order_id",
    orders, "order_id",
    "Payments -> Orders"
)

check_orphans(
    reviews, "order_id",
    orders, "order_id",
    "Reviews -> Orders"
)

print("\nCOMPOSITE KEY CHECK")
print("=" * 65)

duplicate_items = items.duplicated(
    subset=["order_id", "order_item_id"]
).sum()

print(
    "Order items (order_id, order_item_id): "
    f"duplicate pairs = {duplicate_items:,}"
)

print("\nRELATIONSHIP CHECK COMPLETED")
