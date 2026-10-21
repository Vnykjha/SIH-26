# CREPISENSE Project Context

## Project summary

CREPISENSE is an offline-first OA (osteoarthritis) risk screening system for the Northeast Region (NER), built for health workers to screen patients in low-connectivity environments.

Core idea: screen before diagnosis. This is a triage layer, not an X-ray diagnosis tool.

The app is designed around a standard workflow:
1. Patient intake
2. WOMAC/KOOS questionnaire
3. Mobility test
4. Local risk calculation
5. Report output
6. Local persistence
7. Opportunistic cloud sync when connectivity returns

## Repo structure

- `README.md` — project overview, objective, stacks, and commands
- `docs/architecture.md` — system architecture and design principles
- `docs/data_schema.md` — data contract shared across mobile app, ML model, and dashboard
- `docs/WOMAC_KOOS_QUESTIONNAIRE.md` — questionnaire reference and scoring context
- `mobile_app/` — Flutter mobile app (Tier 1 / primary implementation)
- `ml_model/` — ML training pipeline and TFLite export flow
- `web_dashboard/` — React admin dashboard
- `hardware_firmware/` — optional ESP32 IMU puck roadmap

## Architecture principles

- Offline-first: field workflows must work with no connectivity.
- Sync is opportunistic, not required for screening.
- Local SQLite is the source of truth during field operations.
- Firestore is used for later syncing and admin dashboard visibility.
- The dashboard is read-only and should not directly drive mobile app logic.
- The model is run on-device, not remotely.

## Build tiers

- Tier 1: Core workflow, screening app, local DB, on-device risk scoring
- Tier 2: Multilingual UI, phone IMU mobility test, dashboard, Firebase sync
- Tier 3: Optional ESP32 IMU puck, GIS/Bhuvan maps, X-ray module, encryption

## Tech stack

- Mobile: Flutter + Dart
- Local storage: sqflite
- ML inference: TFLite model generated offline
- Backend sync: Firebase Firestore + Auth
- Dashboard: React + Chart.js
- Optional hardware: ESP32 + IMU + BLE

## Main implementation status

The repository already contains a substantial starter implementation, not just an empty scaffold.

### Mobile app

Main app entry: `mobile_app/lib/main.dart`

Key mobile modules:
- `mobile_app/lib/main.dart` — app shell, localization, home screen, startup flow
- `mobile_app/lib/screens/intake_screen.dart` — patient registration intake flow
- `mobile_app/lib/screens/questionnaire_screen.dart` — WOMAC questionnaire UI
- `mobile_app/lib/screens/mobility_test_screen.dart` — mobility assessment screen
- `mobile_app/lib/screens/results_screen.dart` — final report view and auto-save logic
- `mobile_app/lib/screens/screening_history_screen.dart` — saved record history

### Data models

- `mobile_app/lib/models/patient.dart`
- `mobile_app/lib/models/questionnaire_response.dart`
- `mobile_app/lib/models/mobility_test_result.dart`
- `mobile_app/lib/models/risk_result.dart`
- `mobile_app/lib/models/screening.dart`

These models follow the shared contract in `docs/data_schema.md` and store patient, questionnaire, mobility, and risk data in snake_case fields.

### Services

- `mobile_app/lib/services/database_service.dart`
  - Local SQLite database for screening records
  - stores screenings in `screenings` table
  - supports insert, query, unsynced retrieval, sync marking, risk counts

- `mobile_app/lib/services/sync_service.dart`
  - handles background sync from local SQLite to Firestore
  - uses Firestore collection `screenings`

- `mobile_app/lib/services/ml_inference_service.dart`
  - clinical-weighted OA risk model
  - maps WOMAC, age, BMI, prior injury, cadence, and variance into risk categories

- `mobile_app/lib/services/accelerometer_feature_extractor.dart`
  - computes peak acceleration, variance, cadence estimate, kinetic energy

### Dashboard

- `web_dashboard/src/App.jsx` — admin dashboard UI
- `web_dashboard/src/services/dashboard_data_service.js` — Firestore or demo-data service layer

### ML model

- `ml_model/train.py` — training pipeline for risk model
- `ml_model/export_tflite.py` — converts model to TFLite format
- `ml_model/data/` — training data folder

## Shared data contract

The project depends on a common schema described in `docs/data_schema.md`.

### Patient fields
- patient_id
- name
- age
- sex
- occupation
- bmi
- prior_injury_history
- preferred_language
- camp_id / district

### Questionnaire fields
- pain_score
- stiffness_score
- function_score
- total_womac_score
- responses_raw_json

### Mobility test fields
- test_type
- test_variant
- duration_seconds
- peak_accel
- accel_variance
- cadence_cps
- kinetic_energy
- imu_puck_features_json (nullable)

### Risk result fields
- risk_level
- kl_grade
- confidence
- model_version
- computed_at
- screening_mode

### Screening record composite
- screening_id
- patient details
- questionnaire details
- mobility test details
- risk result details
- synced flag
- created_at

## Key workflows already implemented

### 1. Intake workflow
- Patient form captures name, age, sex, occupation, height/weight, previous injury history, language, camp, and district.
- BMI is calculated automatically in `Patient` model.

### 2. Questionnaire workflow
- Standard WOMAC scoring is implemented.
- 24 questions are represented in `QuestionnaireResponse.standardWomacQuestions`.
- The score totals are computed automatically and saved to the database.

### 3. Mobility test workflow
- Accelerometer metrics are extracted from motion data.
- Raw motion readings are converted into a feature dictionary used by the inference engine.

### 4. Risk prediction workflow
- `MLInferenceService.predictRisk(...)` produces a clinical risk assessment using weighted markers.
- Risk is mapped to Low / Medium / High according to clinical rule thresholds.
- Model version is tracked and confidence is included.

### 5. Local record persistence
- Screenings are saved to SQLite in the `screenings` table.
- `DatabaseService.insertScreening()` writes a full screening record.
- `getUnsyncedScreenings()` fetches records not yet synced.

### 6. Sync workflow
- `SyncService.syncPendingRecords()` attempts to push unsynced records to Firestore.
- It marks synced screenings as completed when upload succeeds.

### 7. Results screen
- Results screen displays:
  - risk band (Low/Medium/High)
  - KL grade
  - confidence
  - WOMAC subscale scores
  - model mode
  - patient summary info
- It auto-saves the screening before or during reporting, then syncs if possible

## Notable implementation details

### Risk model logic
`MLInferenceService` uses a clinical-weighted composite score:
- WOMAC total score: 42%
- Age: 15%
- BMI: 13%
- Prior injury: 12%
- Cadence: 10%
- Accel variance: 8%

This is not a pure TensorFlow Lite inference yet; it is a rule-based / clinical-weighted scoring model using regression-like thresholds.

### Data serialization conventions
- SQLite uses snake_case columns matching the schema contract.
- Dart models convert to/from maps with snake_case keys.
- `Screening.toMap()` merges patient, questionnaire, mobility, and risk maps into a combined record.

### Firestore compatibility assumptions
- Firestore docs are stored with nested `patient`, `questionnaire`, `risk_result`, etc., as well as flattened fields in some dashboard code.
- The dashboard service tries to access both shapes via `...data`, `...patient`, `...questionnaire`, and `...risk` flattening.

## Current project state

The repo is in a semi-implemented but structured state:
- Core architecture and domain models exist.
- Major screens are present.
- Local storage and risk scoring logic are already implemented.
- Dashboard is partially ready and uses demo fallback data.
- Hardware + MLOps layers are roadmap/prototype level.

## Potential issues / observations to watch

These are not necessarily defects, but they are important to track while continuing development:

1. The app uses Firebase initialization immediately in `main()`, but the app is designed to still work offline.
2. The scoring logic is currently a clinical heuristic rather than a trained TFLite model, even though the architecture mentions TFLite.
3. The schema and implementation need to stay aligned as fields evolve, especially `responses_raw_json`, `imu_puck_features_json`, and nested Firestore data shapes.
4. The dashboard may rely on data shape assumptions that could drift from the mobile app’s storage schema.
5. The app includes a broad set of features already, so future work should focus on correctness, workflow completion, and integration rather than starting from zero.

## Suggested workflow for ongoing building

Recommended implementation order:
1. Verify and stabilize core mobile flow
2. Ensure data schema consistency across app + dashboard
3. Improve or replace ML scoring logic with trained model integration
4. Build real Firestore sync validation
5. Expand multilingual support and UX polish
6. Add IMU/puck enhancement flow and optional hardware integration
7. Complete admin dashboard analytics and reporting

## Important files to keep in context for future sessions

- [README.md](d:/sih-oa-screening/README.md)
- [docs/architecture.md](d:/sih-oa-screening/docs/architecture.md)
- [docs/data_schema.md](d:/sih-oa-screening/docs/data_schema.md)
- [mobile_app/lib/main.dart](d:/sih-oa-screening/mobile_app/lib/main.dart)
- [mobile_app/lib/screens/results_screen.dart](d:/sih-oa-screening/mobile_app/lib/screens/results_screen.dart)
- [mobile_app/lib/services/ml_inference_service.dart](d:/sih-oa-screening/mobile_app/lib/services/ml_inference_service.dart)
- [mobile_app/lib/services/database_service.dart](d:/sih-oa-screening/mobile_app/lib/services/database_service.dart)
- [mobile_app/lib/services/sync_service.dart](d:/sih-oa-screening/mobile_app/lib/services/sync_service.dart)
- [mobile_app/lib/models/screening.dart](d:/sih-oa-screening/mobile_app/lib/models/screening.dart)
- [web_dashboard/src/App.jsx](d:/sih-oa-screening/web_dashboard/src/App.jsx)
- [web_dashboard/src/services/dashboard_data_service.js](d:/sih-oa-screening/web_dashboard/src/services/dashboard_data_service.js)

## Notes for future sessions

This file should be updated as the project evolves. Any new screens, architecture changes, schema changes, model changes, or major implementation decisions should be appended here so subsequent chat sessions retain accurate context.

It is especially useful to update this file when:
- new features are implemented
- a bug fix changes the app workflow
- schema fields change
- the model or scoring method changes
- Firebase sync behavior changes
- the dashboard or hardware integration evolves

## Last updated

- Initial context created: 2026-10-20
- Auth + storage + dashboard flow added: 2026-10-20
  - Added a health-worker login flow with demo credentials for the app
  - Added local SQLite-backed health worker table and login validation
  - Added recorded-by tracking to screenings
  - Exposed recorded worker information in the dashboard table
  - Confirmed dashboard build passes and can display live/demo screening data
- Android Firebase setup started: 2026-10-21
  - `mobile_app/android/app/google-services.json` is present and its Android package matches `applicationId` / namespace `com.example.crepisense`; the Firebase project ID in the file is `crepisense`.
  - Added the Google Services Gradle plugin (`com.google.gms.google-services` 4.4.2) to the Android app.
  - Set Android `compileSdk` to 36 to satisfy current `sqflite_android` and `tflite_flutter` plugin requirements.
  - Upgraded FlutterFire packages to `firebase_core` 5.0.0, `firebase_auth` 7.0.0, and `cloud_firestore` 7.0.0 to resolve the old `firebase_auth` Android compileSdk 33 metadata failure.
  - Verified `flutter build apk --debug` succeeds. Non-blocking Flutter warnings remain for plugins applying Kotlin Gradle Plugin and Firestore unchecked operations.
  - Dashboard `.env.local` has all six expected Firebase variables and points to project `crepisense` (values intentionally not recorded here).
- Login, language, and cloud-sync troubleshooting: 2026-10-21
  - The language picker was disconnected from `MaterialApp.locale`; root state now receives language selections on login and home screens.
  - Login email/password fields now start blank; demo credentials remain available only through the explicit demo-access button.
  - Removed pre-authentication sync at app startup. Pending local screenings sync when the signed-in home screen loads, and Firestore failures are returned to the UI instead of silently discarded.
  - Dashboard no longer substitutes dummy screenings for a configured-but-empty or inaccessible Firestore database; it shows an empty state or the Firestore read error. Demo data is used only when Firebase environment configuration is absent.
  - Firestore is still empty in the user's console screenshot. Dashboard Firebase email/password sign-in is now implemented; account/admin-doc and rules setup are required before it can read screening data.
  - The SQLite migration path does not delete saved screenings. If older screenings are absent on-device, check whether app data was cleared/reinstalled or the previous build used another app ID/device; cloud setup itself does not erase local SQLite rows.
  - Added admin-only access: a signed-in account must have `admins/{uid}` with `role: "admin"` to access dashboard screening reads.
  - Added `firestore.rules`: authenticated mobile users can create/update screenings tagged with their UID in `uploaded_by`; only listed admins can read screenings; clients cannot modify admin membership or delete screenings.
  - Documented project selection, admin document setup, and rules/hosting deployment in `web_dashboard/README.md`. Rules are not deployed automatically.
  - Verified the Android debug APK builds, dashboard production build succeeds, `firebase.json` parses, and the connected Flutter app hot-restarted without runtime errors. Flutter analysis reports no code errors, but exits nonzero due to the missing `flutter_lints` include and existing warnings/deprecations.
- Dashboard browser console fixes: 2026-10-21
  - React hook-order error fixed by calling memo hooks before any authentication-related conditional returns.
  - Added a project favicon and reference in `web_dashboard/index.html` to avoid `/favicon.ico` missing-resource noise.
  - Verified the Vite production build succeeds.
- Showing health-worker names in dashboard: 2026-10-21
  - Firebase login now uses the Auth profile display name when present, otherwise derives a readable name from the email prefix.
  - Firestore sync writes that value to `recorded_by_name` while keeping `recorded_by` / `uploaded_by` identifiers available for attribution and rules.
  - Dashboard prefers `recorded_by_name` and masks UID-shaped legacy `recorded_by` values as "Health worker". Existing Firestore documents without the name field need a future sync/backfill to show a specific person.
  - Verified Android APK and dashboard production builds; hot-restarted the connected phone app with no runtime errors.
- Health-worker registration: 2026-10-21
  - Added registration option to mobile login. It creates a Firebase Authentication Email/Password user, sets Firebase Auth displayName to the entered name, and signs the new health worker in.
  - Registration validates name, email, minimum six-character password, and password confirmation, and presents localized messages in English, Hindi, Bengali, and Assamese.
  - Registration is Firebase-only and never creates an admin or changes role claims/admin documents. Firebase Console must have Email/Password sign-in enabled.
- Removing demo login UI: 2026-10-21
  - Removed the demo quick-login button and displayed demo credentials from the mobile login screen, along with their unused localization strings.
  - The local demo account bootstrap and fallback authentication behavior remain in `AuthService`; only the login-page demo information was removed.
  - Verified the Android debug APK builds and hot-restarted the app on the connected moto g85 5G.
- Dashboard NER location filters: 2026-10-21
  - Added linked State and District filters for Arunachal Pradesh, Assam, Manipur, Meghalaya, Mizoram, Nagaland, Sikkim, and Tripura.
  - Dashboard normalizes district code spelling/spacing (such as `District-01 Assam` and `district -01 assam`) into one canonical location for the table and activity chart. Codes are keyed within their state to avoid cross-state mixing.
  - This is a dashboard-side normalization; mobile intake still stores the location as free text, and old Firestore records are interpreted from a recognized state suffix or an optional `state` field.
