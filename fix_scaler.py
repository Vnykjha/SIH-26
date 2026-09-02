"""
Fix the scaler_params.json by recomputing from the freshly generated synthetic dataset.
Also exports updated scaler to mobile_app/assets/scaler_params.json.
"""
import json
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "ml_model" / "data" / "oa_risk_dataset.csv"`
ASSET_SCALER_PATH = BASE_DIR / "mobile_app" / "assets" / "scaler_params.json"

FEATURE_COLUMNS = [
    "age", "sex_code", "bmi", "prior_injury",
    "womac_pain", "womac_stiffness", "womac_function",
    "duration_sec", "peak_accel", "accel_variance", "cadence_cps", "kinetic_energy",
]

df = pd.read_csv(DATA_PATH)

# Verify expected columns exist
missing = [c for c in FEATURE_COLUMNS if c not in df.columns]
if missing:
    raise ValueError(f"Missing columns: {missing}")

X = df[FEATURE_COLUMNS].astype(float).to_numpy()

scaler = StandardScaler()
scaler.fit(X)

print("=== Correct Scaler Values ===")
for i, col in enumerate(FEATURE_COLUMNS):
    print(f"  {col}: mean={scaler.mean_[i]:.4f}, std={scaler.scale_[i]:.4f}")

scaler_params = {
    "feature_columns": FEATURE_COLUMNS,
    "mean": scaler.mean_.astype(float).tolist(),
    "scale": scaler.scale_.astype(float).tolist(),
}

with open(ASSET_SCALER_PATH, "w", encoding="utf-8") as f:
    json.dump(scaler_params, f)

print(f"\n✅ Updated scaler_params.json saved to: {ASSET_SCALER_PATH}")
print("\n=== Quick Sanity Check ===")
print(f"cadence_cps range in data: {df['cadence_cps'].min():.2f} – {df['cadence_cps'].max():.2f}")
print(f"accel_variance range in data: {df['accel_variance'].min():.3f} – {df['accel_variance'].max():.3f}")
print(f"KL grade distribution:\n{df['kl_grade'].value_counts().sort_index()}")
