# Synthetic Knee OA Screening Dataset

Synthetic dataset for the phone-based knee osteoarthritis (OA) risk
screening pipeline — built for prototyping, demo, and ML pipeline
validation when no real field dataset is yet available.

> **This dataset is entirely synthetic.** It is not real patient data,
> is not clinically validated, and must not be used for actual diagnosis,
> published research claims, or regulatory submissions. Replace with
> real, ethically sourced, IRB-approved field data before any clinical use.

---

## Files

| File | Purpose |
|---|---|
| `generate_dataset.py` | Generates the dataset from scratch (regenerable, seeded) |
| `synthetic_knee_oa_dataset.csv` | The generated dataset (1500 rows by default) |
| `dataset_metadata.json` | Machine-readable metadata: generation logic, clinical grounding, column groups |
| `split_dataset.py` | Stratified train/validation split (by `risk_label`) |
| `train.csv` / `val.csv` | Example 80/20 split output |
| `train_model_example.py` | scikit-learn RandomForest demo — trains, evaluates, saves a model |
| `risk_model.joblib` | Example trained model artifact from the demo script |

---

## Regenerating the dataset

```bash
python3 generate_dataset.py --n 1500 --seed 42 --outdir .
```

- `--n`: number of patient records (500–2000+ supported)
- `--seed`: random seed (same seed + same `--n` = identical dataset, fully reproducible)
- `--outdir`: where to write the CSV + JSON metadata

To create a train/val split and run the demo model:

```bash
python3 split_dataset.py --input synthetic_knee_oa_dataset.csv --outdir .
python3 train_model_example.py --train train.csv --val val.csv
```

---

## Schema

### Patient-level fields

| Column | Type | Notes |
|---|---|---|
| `patient_id` | string | e.g. `P00001` |
| `age` | int | 18–90 |
| `sex` | categorical | `male` / `female` |
| `height_cm`, `weight_kg` | float | sampled by sex; `BMI` derived from these two (kept internally consistent) |
| `BMI` | float | derived, not independently sampled |
| `knee_pain_score`, `stiffness_score`, `functional_limit_score` | float 0–10 | WOMAC/KOOS-style, app's simplified 0–10 digitized scale |
| `activity_level` | categorical | `sedentary` / `light` / `moderate` / `active` |
| `prior_injury` | 0/1 | binary flag |
| `smoking_status` | categorical | `never` / `former` / `current` |
| `comorbidities` | categorical | `none`, `diabetes`, `hypertension`, `obesity`, `diabetes+hypertension`, `cardiovascular`, `other` |
| `symptom_duration_months` | int | 0–240 |
| `mobility_test_type` | categorical | `sit_to_stand` / `timed_up_and_go` |
| `KL_grade` | int 0–4 | latent/"ground truth" radiographic severity used to drive correlations (not an actual X-ray reading) |
| `risk_label` | categorical | `low` / `medium` / `high` — main classification target |
| `final_risk_score` | float 0–100 | continuous risk target (e.g. for a regression head or thresholding) |

### Accelerometer / mobility-test-derived fields

| Column | Notes |
|---|---|
| `total_time`, `movement_time`, `reaction_time` | seconds; grounded in TUG literature ranges |
| `max_acceleration`, `min_acceleration`, `max_relative_acceleration`, `min_relative_acceleration` | m/s² proxies |
| `max_velocity`, `min_velocity`, `average_velocity` | m/s proxies |
| `max_force`, `min_force`, `average_force` | arbitrary-unit force proxies, scaled loosely with body mass |
| `max_power`, `min_power`, `average_power`, `relative_power` | arbitrary-unit power proxies; `relative_power` = `average_power / weight_kg` |
| `stand_up_time` | seconds; sit-to-stand transition specifically |

---

## How the correlations work (KL-grade → risk logic)

1. A single latent **`severity_index`** (0–1) is computed per synthetic
   patient from:
   - `KL_grade` (60% weight)
   - `age` (25% weight)
   - `BMI` (15% weight)
   - plus small Gaussian noise

2. **Every other feature is a noisy function of this one shared
   `severity_index`**, not independently randomized per column. This is
   what keeps a given row internally consistent — e.g. a patient with
   high `severity_index` will tend to have high pain/stiffness scores
   *and* a slow `total_time` *and* low `max_velocity`, together, rather
   than these being uncorrelated.

3. `risk_label` is derived from `KL_grade` via a base mapping
   (`0–1 → low`, `2 → medium`, `3–4 → high`), with **8% random label
   noise** (shifted one category up/down) to simulate real-world
   disagreement between symptom/mobility-based risk and radiographic
   grade, and to prevent perfectly separable classes.

4. `final_risk_score` blends `severity_index` (55%) with an
   **observable-only** signal (45%, built from pain/stiffness/function
   scores + `total_time` + `stand_up_time`) plus noise — so a model
   trained on the visible columns has to actually learn the pattern
   rather than have access to a hidden leak.

### Clinical grounding for magnitude/direction (not exact values)

- Timed Up and Go (TUG): healthy older adults (60–80 yrs) average
  ~8.2–10.6s; knee OA patients (grade 1–3) average ~13.5–16.7s with high
  variance; times above ~20–30s indicate serious mobility impairment.
  These ranges anchor `total_time`'s relationship to severity — the
  actual per-row values are re-simulated, not resampled from any source
  study.
- Higher KL grade is well-established in the OA literature as
  correlating with more pain, stiffness, functional limitation, slower
  gait, and higher BMI — used here only to set **direction and rough
  magnitude**, not to reproduce a specific published dataset.

Full generation-logic metadata is also available programmatically in
`dataset_metadata.json`.

---

## Suitability checks already run

- **Class balance** (approx., will vary slightly by seed):
  `low` ~49%, `medium` ~26%, `high` ~24% (community-screening-like skew
  toward low risk, not a hospital OA clinic cohort)
- **KL_grade distribution**: skewed toward 0–2 (screening context), with
  a realistic tail at 3–4
- **Demo classification result** (RandomForest, `train_model_example.py`):
  ~75% validation accuracy, with confusion concentrated in the `medium`
  boundary class (between `low`/`high`) — i.e., not artificially
  perfectly separable, which is what you'd expect from a real screening
  tool

---

## Plugging into your project

- The column names match the `On-device Risk Model` inputs from your
  tech stack doc (questionnaire scores + phone-sensor mobility metrics).
- `train_model_example.py` uses scikit-learn to match your stated
  "scikit-learn → TensorFlow Lite" pipeline — train here, then convert
  the final chosen model architecture (e.g., a small dense NN) with
  `tf.lite.TFLiteConverter` for on-device deployment.
- Swap in real field data later by keeping the same column names/types —
  no changes needed downstream in the model training or app-side
  inference code.
