"""
generate_dataset.py
--------------------
Synthetic dataset generator for a phone-based Knee Osteoarthritis (OA)
screening pipeline (WOMAC/KOOS-style questionnaire + mobility test +
accelerometer-derived features).

WHY SYNTHETIC:
No public dataset combines (a) patient demographics/questionnaire scores,
(b) a phone-accelerometer-derived mobility-test feature set, and (c) a
KL-grade-linked risk label, in the schema this project's app produces.
This script generates a domain-aware synthetic dataset so the ML pipeline,
on-device model, and dashboard can be built/demoed before real field data
is collected.

CLINICAL GROUNDING (sources used to set realistic ranges/directions):
- Timed Up and Go (TUG): healthy older adults average ~8-10s (60-80 yrs);
  knee OA patients average ~13.5-16.7s, with high variance; TUG > 20-30s
  indicates serious mobility impairment.
  (Bohannon meta-data; OARSI/Osteoarthritis & Cartilage 2020 reference
  values; Alghadir 2015 TUG reliability in grade 1-3 knee OA; PROMIS/TKA
  pre-op TUG studies.)
- Higher Kellgren-Lawrence (KL) grade is associated with more pain,
  stiffness, functional limitation, slower gait, poorer balance, and
  greater BMI (well-established OA literature; used here only to set the
  DIRECTION and rough MAGNITUDE of correlations, not to reproduce any
  specific dataset).
- WOMAC/KOOS-style pain/stiffness/function subscales run 0-10 in this
  app's simplified digitized form (per project's own questionnaire
  design, not the original 5-point WOMAC Likert scale).

IMPORTANT CAVEAT:
These are SYNTHETIC, DOMAIN-INFORMED values for prototyping and demo
purposes only. They are NOT real patient data, NOT clinically validated,
and must not be used for actual diagnosis, published research claims, or
regulatory submissions. Replace with real, IRB-approved field data before
any clinical use.
"""

import numpy as np
import pandas as pd
import json
import argparse
from pathlib import Path

# ----------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------

RANDOM_SEED = 42

KL_GRADE_DISTRIBUTION = {
    # Roughly modeled on a COMMUNITY SCREENING population (not a hospital
    # OA clinic) -- skewed toward none/mild since most screened people in
    # a rural camp will NOT have advanced OA. This is a deliberate design
    # choice for a screening-context dataset (as opposed to a diagnostic
    # cohort, which would skew toward higher grades).
    0: 0.30,  # no radiographic OA
    1: 0.22,  # doubtful
    2: 0.23,  # mild
    3: 0.17,  # moderate
    4: 0.08,  # severe
}

ACTIVITY_LEVELS = ["sedentary", "light", "moderate", "active"]
SMOKING_STATUS = ["never", "former", "current"]
COMORBIDITY_OPTIONS = [
    "none", "diabetes", "hypertension", "obesity",
    "diabetes+hypertension", "cardiovascular", "other"
]
MOBILITY_TEST_TYPES = ["sit_to_stand", "timed_up_and_go"]

N_RECORDS_DEFAULT = 1200

# ----------------------------------------------------------------------
# HELPERS
# ----------------------------------------------------------------------

def clip(arr, lo, hi):
    return np.clip(arr, lo, hi)


def sample_kl_grades(n, rng):
    grades = list(KL_GRADE_DISTRIBUTION.keys())
    probs = list(KL_GRADE_DISTRIBUTION.values())
    return rng.choice(grades, size=n, p=probs)


def kl_to_risk_label(kl_grade, noise_flip_prob, rng):
    """
    Map KL grade -> risk_label with a small amount of label noise so the
    classes are not perfectly separable (mirrors real-world screening
    tools, where mobility/pain-based risk doesn't perfectly track
    radiographic grade).
    KL 0-1 -> low, KL 2 -> medium, KL 3-4 -> high (base mapping)
    """
    base_map = {0: "low", 1: "low", 2: "medium", 3: "high", 4: "high"}
    labels = np.array([base_map[g] for g in kl_grade])

    # Inject label noise: a small % of cases get bumped one category
    # up or down, simulating real screening disagreement between
    # symptom-based risk and radiographic severity.
    flip_mask = rng.random(len(labels)) < noise_flip_prob
    order = ["low", "medium", "high"]
    idx = np.array([order.index(l) for l in labels])
    direction = rng.choice([-1, 1], size=len(labels))
    idx_new = clip(idx + np.where(flip_mask, direction, 0), 0, 2)
    return np.array([order[i] for i in idx_new])


# ----------------------------------------------------------------------
# MAIN GENERATOR
# ----------------------------------------------------------------------

def generate_dataset(n_records=N_RECORDS_DEFAULT, seed=RANDOM_SEED):
    rng = np.random.default_rng(seed)

    # ---- Demographics -------------------------------------------------
    # Screening population skews toward older adults (OA risk-relevant),
    # but includes some younger controls for class balance.
    age = clip(rng.normal(loc=52, scale=14, size=n_records), 18, 90).round(0).astype(int)
    sex = rng.choice(["female", "male"], size=n_records, p=[0.55, 0.45])

    # Height/weight sampled by sex with realistic ranges (cm / kg),
    # BMI derived from them (not sampled independently) so the three
    # stay internally consistent.
    height_cm = np.where(
        sex == "male",
        clip(rng.normal(168, 7, n_records), 150, 190),
        clip(rng.normal(155, 6, n_records), 140, 178),
    ).round(1)
    # Base weight, then nudged upward slightly with age (common in
    # midlife) before BMI-based OA correlation is applied later.
    weight_kg = clip(
        rng.normal(loc=height_cm * 0.42 - 10 + (age - 40) * 0.05, scale=8, size=n_records),
        35, 140,
    ).round(1)
    bmi = (weight_kg / ((height_cm / 100) ** 2)).round(1)

    # ---- KL grade (latent "ground truth" severity) --------------------
    kl_grade = sample_kl_grades(n_records, rng)

    # ---- Risk-correlated modifiers -------------------------------------
    # A single latent "severity index" (0-1) built from KL grade + age +
    # BMI drives most downstream features, so correlations are coherent
    # across the whole row instead of being set independently per column.
    kl_norm = kl_grade / 4.0
    age_norm = clip((age - 18) / (90 - 18), 0, 1)
    bmi_norm = clip((bmi - 18) / (40 - 18), 0, 1)

    severity_index = clip(
        0.6 * kl_norm + 0.25 * age_norm + 0.15 * bmi_norm
        + rng.normal(0, 0.06, n_records),  # noise so it's not deterministic
        0, 1,
    )

    # ---- Questionnaire scores (WOMAC/KOOS-style, 0-10 app scale) ------
    knee_pain_score = clip(
        rng.normal(loc=severity_index * 9, scale=1.2, size=n_records), 0, 10
    ).round(1)
    stiffness_score = clip(
        rng.normal(loc=severity_index * 8.5, scale=1.3, size=n_records), 0, 10
    ).round(1)
    functional_limit_score = clip(
        rng.normal(loc=severity_index * 9, scale=1.1, size=n_records), 0, 10
    ).round(1)

    symptom_duration_months = clip(
        rng.exponential(scale=6 + severity_index * 40, size=n_records), 0, 240
    ).round(0).astype(int)

    # ---- Categorical risk-correlated fields ----------------------------
    # Activity level trends lower as severity rises (more pain -> less
    # activity), but every level remains possible (some active people
    # still have OA; some sedentary people don't).
    def sample_activity(sev):
        probs_low_sev = [0.15, 0.30, 0.35, 0.20]   # sedentary..active
        probs_high_sev = [0.45, 0.30, 0.18, 0.07]
        p = [
            lo + (hi - lo) * sev
            for lo, hi in zip(probs_low_sev, probs_high_sev)
        ]
        p = np.array(p) / np.sum(p)
        return rng.choice(ACTIVITY_LEVELS, p=p)

    activity_level = np.array([sample_activity(s) for s in severity_index])

    prior_injury = (rng.random(n_records) < clip(0.10 + 0.35 * severity_index, 0, 0.7)).astype(int)

    smoking_status = rng.choice(SMOKING_STATUS, size=n_records, p=[0.65, 0.22, 0.13])

    def sample_comorbidity(sev, bmi_val):
        # Higher severity/BMI -> higher chance of a comorbidity being present
        p_none = clip(0.75 - 0.5 * sev - (0.1 if bmi_val > 30 else 0), 0.15, 0.9)
        remaining = 1 - p_none
        other_n = len(COMORBIDITY_OPTIONS) - 1
        p_rest = [remaining / other_n] * other_n
        probs = [p_none] + p_rest
        probs = np.array(probs) / np.sum(probs)
        return rng.choice(COMORBIDITY_OPTIONS, p=probs)

    comorbidities = np.array([
        sample_comorbidity(s, b) for s, b in zip(severity_index, bmi)
    ])

    mobility_test_type = rng.choice(MOBILITY_TEST_TYPES, size=n_records, p=[0.6, 0.4])

    # ---- Accelerometer / mobility-test derived features ----------------
    # Grounded in TUG literature: healthy older adults ~8-10s,
    # knee OA patients ~13.5-16.7s (higher variance), severe cases > 20s.
    # sit-to-stand scales similarly to TUG for this synthetic purpose.
    base_time = 8.0 + severity_index * 11.0  # ~8s (healthy) to ~19s (severe)
    total_time = clip(
        rng.normal(loc=base_time, scale=1.5 + severity_index * 2.0, size=n_records),
        5, 45,
    ).round(2)

    # Movement time is the active-motion portion of total_time (excludes
    # the brief reaction/initiation delay before the first movement).
    reaction_time = clip(
        rng.normal(loc=0.3 + severity_index * 0.5, scale=0.12, size=n_records), 0.15, 2.0
    ).round(2)
    movement_time = clip(total_time - reaction_time - rng.normal(0.2, 0.1, n_records), 3, 43).round(2)

    # Kinematics: healthier movement = higher peak accel/velocity/force/
    # power and SMOOTHER (less erratic) signal; OA movement = slower,
    # more hesitant, lower peak output, choppier signal (captured via
    # added noise scaling with severity).
    noise_scale = 1 + severity_index * 1.5

    max_acceleration = clip(
        rng.normal(loc=2.8 - severity_index * 1.3, scale=0.3 * noise_scale, size=n_records), 0.5, 4.0
    ).round(3)
    min_acceleration = clip(
        rng.normal(loc=-2.5 + severity_index * 1.1, scale=0.3 * noise_scale, size=n_records), -4.0, -0.3
    ).round(3)
    max_relative_acceleration = (max_acceleration - rng.normal(0.1, 0.05, n_records)).round(3)
    min_relative_acceleration = (min_acceleration + rng.normal(0.1, 0.05, n_records)).round(3)

    max_velocity = clip(
        rng.normal(loc=1.4 - severity_index * 0.8, scale=0.15 * noise_scale, size=n_records), 0.15, 2.0
    ).round(3)
    min_velocity = clip(
        rng.normal(loc=-0.3 - severity_index * 0.15, scale=0.08 * noise_scale, size=n_records), -0.9, -0.02
    ).round(3)
    average_velocity = clip((max_velocity + min_velocity) / 2 + rng.normal(0, 0.05, n_records), 0.02, 1.5).round(3)

    # Force/power proxies (arbitrary units consistent with a phone IMU +
    # body-mass-scaled estimate) -- higher severity -> lower peak
    # force/power generated during the sit-to-stand / TUG transition.
    bodymass_factor = (weight_kg / 70.0)
    max_force = clip(
        rng.normal(loc=(650 - severity_index * 220) * bodymass_factor / bodymass_factor.mean(),
                   scale=60 * noise_scale, size=n_records), 150, 900
    ).round(1)
    min_force = clip(
        rng.normal(loc=(80 - severity_index * 20), scale=15 * noise_scale, size=n_records), 5, 150
    ).round(1)
    average_force = clip((max_force * 0.4 + min_force * 0.6) + rng.normal(0, 20, n_records), 20, 500).round(1)

    max_power = clip(
        rng.normal(loc=(420 - severity_index * 200), scale=50 * noise_scale, size=n_records), 60, 700
    ).round(1)
    min_power = clip(
        rng.normal(loc=(30 - severity_index * 10), scale=8 * noise_scale, size=n_records), 2, 80
    ).round(1)
    average_power = clip((max_power * 0.45 + min_power * 0.55) + rng.normal(0, 15, n_records), 10, 400).round(1)
    relative_power = clip(average_power / weight_kg, 0.2, 8).round(3)

    stand_up_time = clip(
        rng.normal(loc=1.2 + severity_index * 2.0, scale=0.3 * noise_scale, size=n_records), 0.6, 6.0
    ).round(2)

    # ---- Risk label + final_risk_score ---------------------------------
    risk_label = kl_to_risk_label(kl_grade, noise_flip_prob=0.08, rng=rng)

    # final_risk_score (0-100): weighted blend of severity_index and
    # questionnaire/mobility signals, plus noise -- this is the target
    # a regression head (or a thresholded classifier) would be trained
    # to reproduce; it is intentionally NOT a pure copy of severity_index
    # so the model has to learn from the observable features, not a
    # hidden leak.
    observable_signal = (
        0.28 * (knee_pain_score / 10)
        + 0.18 * (stiffness_score / 10)
        + 0.22 * (functional_limit_score / 10)
        + 0.20 * clip((total_time - 6) / 25, 0, 1)
        + 0.12 * clip((stand_up_time - 0.6) / 5, 0, 1)
    )
    final_risk_score = clip(
        (0.55 * severity_index + 0.45 * observable_signal) * 100
        + rng.normal(0, 4, n_records),
        0, 100,
    ).round(1)

    # ---- Assemble dataframe --------------------------------------------
    df = pd.DataFrame({
        "patient_id": [f"P{str(i+1).zfill(5)}" for i in range(n_records)],
        "age": age,
        "sex": sex,
        "height_cm": height_cm,
        "weight_kg": weight_kg,
        "BMI": bmi,
        "knee_pain_score": knee_pain_score,
        "stiffness_score": stiffness_score,
        "functional_limit_score": functional_limit_score,
        "activity_level": activity_level,
        "prior_injury": prior_injury,
        "smoking_status": smoking_status,
        "comorbidities": comorbidities,
        "symptom_duration_months": symptom_duration_months,
        "mobility_test_type": mobility_test_type,
        "total_time": total_time,
        "movement_time": movement_time,
        "reaction_time": reaction_time,
        "max_acceleration": max_acceleration,
        "min_acceleration": min_acceleration,
        "max_relative_acceleration": max_relative_acceleration,
        "min_relative_acceleration": min_relative_acceleration,
        "max_velocity": max_velocity,
        "min_velocity": min_velocity,
        "average_velocity": average_velocity,
        "max_force": max_force,
        "min_force": min_force,
        "average_force": average_force,
        "max_power": max_power,
        "min_power": min_power,
        "average_power": average_power,
        "relative_power": relative_power,
        "stand_up_time": stand_up_time,
        "KL_grade": kl_grade,
        "risk_label": risk_label,
        "final_risk_score": final_risk_score,
    })

    return df


# ----------------------------------------------------------------------
# METADATA (for the accompanying JSON)
# ----------------------------------------------------------------------

def build_metadata(n_records, seed):
    return {
        "dataset_name": "synthetic_knee_oa_screening_dataset",
        "n_records": n_records,
        "random_seed": seed,
        "is_synthetic": True,
        "generation_method": "domain-aware parametric simulation (numpy), not pure random / not resampled from any real dataset",
        "purpose": [
            "ML model training/prototyping for the on-device risk classifier",
            "Demo app testing end-to-end (intake -> mobility test -> risk output)",
            "Model validation / pipeline smoke-testing before real field data is available",
        ],
        "clinical_grounding": {
            "KL_grade_distribution": KL_GRADE_DISTRIBUTION,
            "TUG_reference_values_seconds": {
                "healthy_older_adults_60_80yo": "~8.2-10.6s (mean, by age/sex)",
                "knee_OA_patients_grade_1_3": "~13.5-16.7s (mean, high SD)",
                "severe_impairment_threshold": ">20-30s",
                "source_note": "Used only to set the direction/rough magnitude of total_time by severity; values are re-simulated, not resampled from source studies."
            },
            "core_correlation_logic": (
                "A single latent severity_index (0-1) is computed per patient from "
                "KL_grade (60% weight), age (25% weight), and BMI (15% weight), plus "
                "small Gaussian noise. All downstream features (pain/stiffness/function "
                "scores, total_time, stand_up_time, acceleration/velocity/force/power) "
                "are sampled as noisy functions of this shared severity_index, so "
                "correlations are internally consistent across each row instead of "
                "being independently randomized per column."
            ),
            "label_noise": (
                "8% of risk_label values are randomly shifted one category up or down "
                "from the KL-grade-based mapping, to simulate real-world disagreement "
                "between symptom/mobility-based screening risk and radiographic grade, "
                "and to avoid perfectly separable classes."
            ),
        },
        "columns": {
            "patient_level": [
                "patient_id", "age", "sex", "BMI", "height_cm", "weight_kg",
                "knee_pain_score", "stiffness_score", "functional_limit_score",
                "activity_level", "prior_injury", "smoking_status", "comorbidities",
                "symptom_duration_months", "mobility_test_type", "KL_grade",
                "risk_label", "final_risk_score",
            ],
            "accelerometer_derived": [
                "total_time", "movement_time", "reaction_time",
                "max_acceleration", "min_acceleration",
                "max_relative_acceleration", "min_relative_acceleration",
                "max_velocity", "min_velocity", "average_velocity",
                "max_force", "min_force", "average_force",
                "max_power", "min_power", "average_power", "relative_power",
                "stand_up_time",
            ],
        },
        "disclaimer": (
            "This dataset is entirely SYNTHETIC and intended for prototyping and "
            "demo purposes only. It is not derived from real patients, has not been "
            "clinically validated, and must not be used for actual diagnosis, "
            "published clinical research claims, or regulatory submissions. Replace "
            "with real, ethically sourced and IRB-approved field data before any "
            "clinical use."
        ),
    }


# ----------------------------------------------------------------------
# CLI
# ----------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate synthetic knee OA screening dataset.")
    parser.add_argument("--n", type=int, default=N_RECORDS_DEFAULT, help="Number of records to generate")
    parser.add_argument("--seed", type=int, default=RANDOM_SEED, help="Random seed for reproducibility")
    parser.add_argument("--outdir", type=str, default=".", help="Output directory")
    args = parser.parse_args()

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    df = generate_dataset(n_records=args.n, seed=args.seed)
    csv_path = outdir / "synthetic_knee_oa_dataset.csv"
    df.to_csv(csv_path, index=False)

    meta = build_metadata(args.n, args.seed)
    meta_path = outdir / "dataset_metadata.json"
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)

    print(f"Generated {len(df)} records.")
    print(f"CSV saved to: {csv_path}")
    print(f"Metadata saved to: {meta_path}")
    print("\nClass balance (risk_label):")
    print(df["risk_label"].value_counts())
    print("\nKL_grade distribution:")
    print(df["KL_grade"].value_counts().sort_index())
