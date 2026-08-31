"""
CREPISENSE — Clinical-Grade Synthetic Dataset Generator for OA Risk Screening
Generates a realistic dataset for Tier 1 screening with a KL-grade-aligned target.
The model learns from WOMAC/OA symptom severity and mobility features extracted
from a phone accelerometer, with the app defaulting to Standard Screening.
"""

import json
import os

import numpy as np
import pandas as pd

FEATURE_COLUMNS = [
    "age",
    "sex_code",
    "bmi",
    "prior_injury",
    "womac_pain",
    "womac_stiffness",
    "womac_function",
    "duration_sec",
    "peak_accel",
    "accel_variance",
    "cadence_cps",
    "kinetic_energy",
]


def generate_dataset(num_samples=3000, random_seed=42):
    rng = np.random.default_rng(random_seed)

    age = rng.integers(35, 85, size=num_samples)
    sex_code = rng.choice([0, 1], size=num_samples, p=[0.52, 0.48])
    bmi = np.round(rng.normal(27.5, 4.8, size=num_samples).clip(18.5, 45.0), 1)
    prior_injury = rng.choice([0, 1], size=num_samples, p=[0.7, 0.3])

    severity = (
        0.34 * ((age - 35) / 50.0)
        + 0.28 * np.maximum(0.0, bmi - 24.0) / 18.0
        + 0.20 * prior_injury
        + 0.18 * sex_code
    )
    severity += rng.normal(0.0, 0.12, size=num_samples)
    severity = np.clip(severity, 0.0, 1.0)

    pain_sums = []
    stiffness_sums = []
    function_sums = []
    womac_raw_list = []

    for i in range(num_samples):
        sev = severity[i]

        pain_scores = [
            int(rng.choice([0, 1, 2, 3, 4], p=np.array([
                max(0.02, 1.0 - 1.25 * sev),
                max(0.02, 0.75 * sev * (1 - sev)),
                max(0.02, 0.9 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ]) / max(0.02, sum([
                max(0.02, 1.0 - 1.25 * sev),
                max(0.02, 0.75 * sev * (1 - sev)),
                max(0.02, 0.9 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ])))) for _ in range(5)
        ]

        stiffness_scores = [
            int(rng.choice([0, 1, 2, 3, 4], p=np.array([
                max(0.02, 1.0 - 1.15 * sev),
                max(0.02, 0.7 * sev * (1 - sev)),
                max(0.02, 0.8 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ]) / max(0.02, sum([
                max(0.02, 1.0 - 1.15 * sev),
                max(0.02, 0.7 * sev * (1 - sev)),
                max(0.02, 0.8 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ])))) for _ in range(2)
        ]

        function_scores = [
            int(rng.choice([0, 1, 2, 3, 4], p=np.array([
                max(0.02, 1.0 - 1.3 * sev),
                max(0.02, 0.8 * sev * (1 - sev)),
                max(0.02, 0.9 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ]) / max(0.02, sum([
                max(0.02, 1.0 - 1.3 * sev),
                max(0.02, 0.8 * sev * (1 - sev)),
                max(0.02, 0.9 * sev * (1 - sev)),
                max(0.02, 0.7 * sev * sev),
                max(0.02, 0.9 * sev * sev),
            ])))) for _ in range(17)
        ]

        raw_24 = pain_scores + stiffness_scores + function_scores
        womac_raw_list.append(json.dumps(raw_24))
        pain_sums.append(sum(pain_scores))
        stiffness_sums.append(sum(stiffness_scores))
        function_sums.append(sum(function_scores))

    pain_sums = np.asarray(pain_sums, dtype=float)
    stiffness_sums = np.asarray(stiffness_sums, dtype=float)
    function_sums = np.asarray(function_sums, dtype=float)

    duration_sec = np.round(
        np.clip(8.5 + severity * 14.0 + rng.normal(0.0, 1.5, num_samples), 6.0, 38.0), 2
    )
    peak_accel = np.round(
        np.clip(3.9 - severity * 1.5 + rng.normal(0.0, 0.28, num_samples), 0.9, 4.8), 2
    )
    accel_variance = np.round(
        np.clip(0.18 + severity * 0.95 + rng.normal(0.0, 0.12, num_samples), 0.05, 2.8), 3
    )
    cadence_cps = np.round(
        np.clip(2.4 - severity * 0.9 + rng.normal(0.0, 0.18, num_samples), 0.4, 3.2), 2
    )
    kinetic_energy = np.round(
        np.clip(18.0 - severity * 8.0 + rng.normal(0.0, 1.8, num_samples), 2.0, 28.0), 2
    )

    womac_total_ratio = (pain_sums + stiffness_sums + function_sums) / 96.0
    clinical_index = (
        0.42 * womac_total_ratio
        + 0.20 * (duration_sec / 35.0)
        + 0.18 * (accel_variance / 2.5)
        + 0.10 * (age / 85.0)
        + 0.10 * (bmi / 40.0)
    )

    kl_grade = np.digitize(
        clinical_index,
        bins=[0.10, 0.22, 0.38, 0.60, 0.82],
        right=False,
    ).astype(int)
    kl_grade = np.clip(kl_grade, 0, 4)

    risk_level = np.where(
        kl_grade <= 1, "Low",
        np.where(kl_grade == 2, "Medium", "High")
    )

    df = pd.DataFrame({
        "age": age,
        "sex_code": sex_code,
        "bmi": bmi,
        "prior_injury": prior_injury,
        "womac_pain": pain_sums.round().astype(int),
        "womac_stiffness": stiffness_sums.round().astype(int),
        "womac_function": function_sums.round().astype(int),
        "duration_sec": duration_sec,
        "peak_accel": peak_accel,
        "accel_variance": accel_variance,
        "cadence_cps": cadence_cps,
        "kinetic_energy": kinetic_energy,
        "kl_grade": kl_grade,
        "risk_level": risk_level,
        "womac_total": (pain_sums + stiffness_sums + function_sums).round().astype(int),
        "womac_raw_json": womac_raw_list,
        "screening_mode": "standard",
    })

    return df


if __name__ == "__main__":
    data_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(data_dir, "oa_risk_dataset.csv")
    df = generate_dataset()
    df.to_csv(output_path, index=False)

    print(f"Dataset generated at: {output_path}")
    print(f"Dataset shape: {df.shape}")
    print("KL grade counts:\n" + str(df["kl_grade"].value_counts().sort_index().to_string()))
    print("Risk counts:\n" + str(df["risk_level"].value_counts().to_string()))
