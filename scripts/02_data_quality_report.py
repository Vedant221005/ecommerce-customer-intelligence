
from pathlib import Path
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "data" / "raw"
REPORT_DIR = PROJECT_DIR / "reports"

REPORT_DIR.mkdir(parents=True, exist_ok=True)

files = sorted(RAW_DIR.glob("*.csv"))
summary = []

for file in files:
    df = pd.read_csv(file, low_memory=False)

    missing_cells = int(df.isna().sum().sum())
    total_cells = df.shape[0] * df.shape[1]

    summary.append({
        "file": file.name,
        "rows": len(df),
        "columns": len(df.columns),
        "missing_cells": missing_cells,
        "missing_percentage": round(
            missing_cells / total_cells * 100, 2
        ) if total_cells else 0,
        "duplicate_rows": int(df.duplicated().sum()),
    })

report = pd.DataFrame(summary)

output_file = REPORT_DIR / "data_quality_summary.csv"
report.to_csv(output_file, index=False)

print("\nDATA QUALITY SUMMARY")
print("=" * 90)
print(report.to_string(index=False))
print(f"\nReport saved to: {output_file}")

# Investigate order status and date completeness
orders_file = RAW_DIR / "olist_orders_dataset.csv"
orders = pd.read_csv(orders_file)

print("\nORDER STATUS COUNTS")
print("=" * 40)
print(orders["order_status"].value_counts(dropna=False).to_string())

print("\nMISSING ORDER TIMESTAMPS")
print("=" * 40)

date_columns = [
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

for column in date_columns:
    print(f"{column}: {orders[column].isna().sum():,}")

print("\nDATA QUALITY REPORT COMPLETED")
