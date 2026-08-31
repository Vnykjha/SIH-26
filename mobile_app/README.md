# mobile_app — Flutter (Tier 1 core)

Health worker's main tool. Offline-first: must work with zero connectivity.

## Structure

- `lib/models/` — Patient, QuestionnaireResponse, MobilityTestResult, RiskResult, Screening (see `/docs/data_schema.md`)
- `lib/screens/` — Intake, Questionnaire, Mobility Test, Results/Report, Patient History
- `lib/services/` — local_db_service (sqflite), ml_inference_service (TFLite), sync_service (Firebase), localization

## Not yet implemented — build order suggestion

1. `pubspec.yaml` — add deps: `sqflite`, `path_provider`, `tflite_flutter`, `firebase_core`, `cloud_firestore`, `firebase_auth`, `flutter_localizations`, `sensors_plus` (for accelerometer)
2. `lib/models/` — data classes matching `/docs/data_schema.md`
3. `lib/screens/intake_screen.dart`
4. `lib/screens/questionnaire_screen.dart`
5. `lib/screens/mobility_test_screen.dart`
6. `lib/services/local_db_service.dart`
7. `lib/services/ml_inference_service.dart` (loads `.tflite` from `ml_model/`)
8. `lib/screens/results_screen.dart`
9. `lib/services/sync_service.dart` (Tier 2)
10. Localization (Tier 2)
