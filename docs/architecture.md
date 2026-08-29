# Architecture Overview

## Design principle

Every field-facing feature works with **zero connectivity**. Sync is
opportunistic, never a dependency.

## Two-mode screening model

- **Standard Screening** (default, always available): questionnaire +
  phone-only mobility test → on-device risk score.
- **Enhanced Screening** (where the IMU puck is available): questionnaire +
  phone test + IMU puck data → refined risk score, same model, sharper input.

## Data flow

```
[Health worker's phone]
   Intake → Questionnaire → Mobility Test (phone accel, or IMU puck via BLE)
        ↓
   On-device TFLite model → Risk Level (Low/Med/High)
        ↓
   SQLite (local, always) ──(when signal available)──> Firebase Firestore
                                                              ↓
                                                    React web dashboard
                                                    (district/MDoNER view)
```

## Component responsibilities

- **mobile_app**: all patient-facing and health-worker-facing logic;
  must fully function with the device in airplane mode.
- **ml_model**: trained offline, exported to `.tflite`, bundled into the
  app at build time (not downloaded at runtime for v1).
- **web_dashboard**: read-only aggregation view for admins; consumes
  Firestore data only, never talks to phones directly.
- **hardware_firmware**: ESP32 firmware for the optional IMU puck;
  streams processed motion data over BLE during the ~30s test only.

## Sequence (end-to-end walkthrough)

1. Health worker opens app, zero internet, optionally has IMU puck.
2. New Screening → patient intake (name, age, sex, occupation, BMI, injury history).
3. WOMAC/KOOS questionnaire walked through in patient's preferred language.
4. Mobility test run — phone sensor by default, IMU puck if available/clipped on.
5. "Calculate Risk" → on-device model → Low/Medium/High, instantly, offline.
6. Report reviewed on-screen with patient; plain-language preventive guidance shown.
7. Record saved locally; High risk flagged for priority referral.
8. Auto-sync to Firestore when signal returns.
9. District health officer views dashboard: totals, risk breakdown by
   camp/district, GIS risk clustering (Tier 3).
