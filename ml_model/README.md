# ml_model — risk classifier

scikit-learn training pipeline → exported to TensorFlow Lite for on-device
inference in `mobile_app`.

## Inputs (per `/docs/data_schema.md`)

- Questionnaire subscale scores (pain, stiffness, function)
- Demographics (age, sex, BMI, prior injury)
- Mobility test features (from phone accel or IMU puck)

## Output

- risk_level: Low / Medium / High (+ confidence)

## Not yet implemented — build order suggestion

1. `data/` — start with a synthetic/sample dataset (no real patient data yet)
2. `train.py` — scikit-learn classifier (e.g. RandomForest or gradient
   boosting to start; simple enough to convert)
3. `evaluate.py` — sanity-check accuracy/confusion matrix on held-out split
4. `export_tflite.py` — convert trained model to `.tflite`
5. `model.tflite` — final artifact, copied into `mobile_app/assets/`
6. Document the exact feature vector order here once finalized — it must
   match what `mobile_app/lib/services/ml_inference_service.dart` builds.
