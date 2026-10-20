
from pathlib import Path
import pandas as pd

# Project paths
PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / "data" / "raw"

# Dataset files
csv_files = sorted(DATA_DIR.glob("*.csv"))

if not csv_files:
    raise FileNotFoundError(
        f"No CSV files found in {DATA_DIR}"
    )

print("=" * 70)
print("OLIST E-COMMERCE DATASET INSPECTION")
print("=" * 70)

print(f"\nDataset folder: {DATA_DIR}")
print(f"Number of CSV files: {len(csv_files)}")

for file in csv_files:
    print("\n" + "=" * 70)
    print(f"FILE: {file.name}")
    print("=" * 70)

    try:
        df = pd.read_csv(file, low_memory=False)

        print(f"Rows: {df.shape[0]:,}")
        print(f"Columns: {df.shape[1]}")

        print("\nColumn names:")
        print(df.columns.tolist())

        print("\nData types:")
        print(df.dtypes.to_string())

        print("\nMissing values:")
        missing = df.isnull().sum()
        missing = missing[missing > 0]

        if missing.empty:
            print("No missing values found.")
        else:
            print(missing.to_string())

        print(f"\nDuplicate rows: {df.duplicated().sum():,}")

        print("\nFirst 3 rows:")
        print(df.head(3).to_string(index=False))

    except Exception as error:
        print(f"ERROR reading {file.name}: {error}")

print("\n" + "=" * 70)
print("DATASET INSPECTION COMPLETED")
print("=" * 70)
