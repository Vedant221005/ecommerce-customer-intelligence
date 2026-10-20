
from pathlib import Path
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "data" / "raw"
REPORT_DIR = PROJECT_DIR / "reports"

REPORT_DIR.mkdir(parents=True, exist_ok=True)

orders = pd.read_csv(
    RAW_DIR / "olist_orders_dataset.csv"
)

date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

for column in date_columns:
    orders[column] = pd.to_datetime(
        orders[column], errors="coerce"
    )

print("\n1. ORDER STATUS SUMMARY")
print("=" * 65)

status_summary = (
    orders.groupby("order_status", dropna=False)
    .agg(
        total_orders=("order_id", "count"),
        missing_approval=("order_approved_at",
                          lambda x: x.isna().sum()),
        missing_carrier_date=("order_delivered_carrier_date",
                              lambda x: x.isna().sum()),
        missing_delivery_date=("order_delivered_customer_date",
                               lambda x: x.isna().sum()),
    )
    .reset_index()
)

print(status_summary.to_string(index=False))

print("\n2. DELIVERY TIMING CHECK")
print("=" * 65)

delivered = orders[
    (orders["order_status"] == "delivered")
    & orders["order_delivered_customer_date"].notna()
    & orders["order_purchase_timestamp"].notna()
].copy()

delivered["delivery_days"] = (
    delivered["order_delivered_customer_date"]
    - delivered["order_purchase_timestamp"]
).dt.total_seconds() / 86400

delivered["days_vs_estimate"] = (
    delivered["order_delivered_customer_date"]
    - delivered["order_estimated_delivery_date"]
).dt.total_seconds() / 86400

print(f"Delivered orders analyzed: {len(delivered):,}")
print(
    "Average delivery time: "
    f"{delivered['delivery_days'].mean():.2f} days"
)
print(
    "Median delivery time: "
    f"{delivered['delivery_days'].median():.2f} days"
)
print(
    "Orders delivered after estimated date: "
    f"{(delivered['days_vs_estimate'] > 0).sum():,}"
)
print(
    "Orders delivered on or before estimated date: "
    f"{(delivered['days_vs_estimate'] <= 0).sum():,}"
)

status_summary.to_csv(
    REPORT_DIR / "order_status_investigation.csv",
    index=False,
)

print("\nSaved reports/order_status_investigation.csv")
