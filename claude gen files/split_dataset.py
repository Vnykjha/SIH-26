"""
split_dataset.py
-----------------
Creates a stratified train/validation split of the synthetic OA dataset,
stratified on risk_label so class proportions are preserved in both sets.

Usage:
    python3 split_dataset.py --input synthetic_knee_oa_dataset.csv --outdir .
"""

import argparse
from pathlib import Path
import pandas as pd
from sklearn.model_selection import train_test_split


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=str, default="synthetic_knee_oa_dataset.csv")
    parser.add_argument("--outdir", type=str, default=".")
    parser.add_argument("--test_size", type=float, default=0.2)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(args.input)

    train_df, val_df = train_test_split(
        df,
        test_size=args.test_size,
        random_state=args.seed,
        stratify=df["risk_label"],
    )

    train_path = outdir / "train.csv"
    val_path = outdir / "val.csv"
    train_df.to_csv(train_path, index=False)
    val_df.to_csv(val_path, index=False)

    print(f"Train set: {len(train_df)} rows -> {train_path}")
    print(f"Val set:   {len(val_df)} rows -> {val_path}")
    print("\nTrain class balance:")
    print(train_df["risk_label"].value_counts(normalize=True).round(3))
    print("\nVal class balance:")
    print(val_df["risk_label"].value_counts(normalize=True).round(3))


if __name__ == "__main__":
    main()
