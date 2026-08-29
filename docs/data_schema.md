# Data Schema — Shared Contract

This is the contract that `mobile_app`, `ml_model`, and `web_dashboard` all
build against. Keep it updated as the single source of truth; every other
component's data classes/types should derive from this.

## 1. Patient (intake)

| Field | Type | Notes |
|---|---|---|
| patient_id | string (UUID) | generated on device |
| name | string | |
| age | int | |
| sex | enum (M/F/Other) | |
| occupation | string | free text or dropdown |
| bmi | float | computed from height/weight |
| prior_injury_history | string / bool + notes | |
| preferred_language | string | for questionnaire localization |
| camp_id / district | string | for dashboard aggregation |

## 2. WOMAC/KOOS Questionnaire response

| Field | Type | Notes |
|---|---|---|
| pain_score | int (0–4 per item, summed) | standard WOMAC pain subscale |
| stiffness_score | int | WOMAC stiffness subscale |
| function_score | int | WOMAC physical function subscale |
| responses_raw | list[int] | raw per-item answers, for audit/re-scoring |

## 3. Mobility test result

| Field | Type | Notes |
|---|---|---|
| test_type | enum (phone_only / imu_puck) | which mode was used |
| test_variant | enum (timed_up_and_go / sit_to_stand) | |
| duration_seconds | float | |
| accel_features | object | extracted features (peak accel, variance, cadence, etc.) — define exact feature vector in `ml_model/` |
| imu_puck_features | object (nullable) | present only if Enhanced Screening mode used |

## 4. Risk result (model output)

| Field | Type | Notes |
|---|---|---|
| risk_level | enum (Low / Medium / High) | |
| confidence | float (0–1) | model output probability |
| model_version | string | for traceability across TFLite exports |
| computed_at | datetime | |
| screening_mode | enum (standard / enhanced) | phone-only vs IMU-puck-assisted |

## 5. Screening record (composite, what gets stored/synced)

```
Screening {
  screening_id: UUID
  patient: Patient
  questionnaire: QuestionnaireResponse
  mobility_test: MobilityTestResult
  risk_result: RiskResult
  synced: bool
  created_at: datetime
}
```

## Notes

- All field names above should be mirrored exactly (snake_case) across
  Dart models, the Python training pipeline, and Firestore documents,
  to avoid translation bugs at sync time.
- `accel_features` exact feature engineering (window size, sampling rate,
  which statistics) needs to be finalized in `ml_model/train.py` first —
  the Flutter mobility-test screen must extract the *same* features at
  inference time.
