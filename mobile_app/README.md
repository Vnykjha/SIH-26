# mobile_app — Flutter (Tier 1 core)

Health worker's main tool. Offline-first: must work with zero connectivity.

## Structure

- `lib/models/` — Patient, QuestionnaireResponse, MobilityTestResult, RiskResult, Screening (see `/docs/data_schema.md`)
- `lib/screens/` — Intake, Questionnaire, Mobility Test, Results/Report, Patient History
- `lib/services/` — local_db_service (sqflite), ml_inference_service (TFLite), sync_service (Firebase), localization

## Health-worker accounts

The login screen supports Firebase Email/Password sign-in and registration.
To enable registration, turn on **Authentication → Sign-in method →
Email/Password** in the Firebase Console. New accounts appear under
**Authentication → Users**, are assigned the health-worker role by the app,
and are signed in after successful registration. The registration form cannot
create or grant admin access. Admin accounts and dashboard permissions are
managed separately.

The explicit demo login remains available for local demonstrations; it does not
create a Firebase user.
