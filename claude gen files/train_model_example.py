"""
train_model_example.py
-----------------------
Minimal scikit-learn training example showing the synthetic dataset is
usable for a multi-class risk classification demo (low / medium / high),
matching the "scikit-learn -> TFLite" pipeline described in the project's
tech stack.

This is a DEMO/SMOKE-TEST script, not a tuned production model. It shows:
1. Loading train/val splits
2. A simple preprocessing pipeline (numeric + categorical)
3. Training a RandomForestClassifier
4. Reporting accuracy / classification report on the validation set
5. Saving the trained model to disk (joblib) as a starting point for
   later conversion to TensorFlow Lite for on-device inference.

Usage:
    python3 train_model_example.py --train train.csv --val val.csv
"""

import argparse
import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

NUMERIC_FEATURES = [
    "age", "BMI", "height_cm", "weight_kg",
    "knee_pain_score", "stiffness_score", "functional_limit_score",
    "symptom_duration_months",
    "total_time", "movement_time", "reaction_time",
    "max_acceleration", "min_acceleration",
    "max_relative_acceleration", "min_relative_acceleration",
    "max_velocity", "min_velocity", "average_velocity",
    "max_force", "min_force", "average_force",
    "max_power", "min_power", "average_power", "relative_power",
    "stand_up_time",
]

CATEGORICAL_FEATURES = [
    "sex", "activity_level", "smoking_status", "comorbidities",
    "mobility_test_type", "prior_injury",
]

TARGET = "risk_label"


def build_pipeline():
    preprocessor = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), NUMERIC_FEATURES),
            ("cat", OneHotEncoder(handle_unknown="ignore"), CATEGORICAL_FEATURES),
        ]
    )
    clf = RandomForestClassifier(
        n_estimators=200,
        max_depth=10,
        random_state=42,
        class_weight="balanced",
    )
    pipeline = Pipeline(steps=[("preprocess", preprocessor), ("model", clf)])
    return pipeline


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", type=str, default="train.csv")
    parser.add_argument("--val", type=str, default="val.csv")
    parser.add_argument("--model_out", type=str, default="risk_model.joblib")
    args = parser.parse_args()

    train_df = pd.read_csv(args.train)
    val_df = pd.read_csv(args.val)

    X_train, y_train = train_df[NUMERIC_FEATURES + CATEGORICAL_FEATURES], train_df[TARGET]
    X_val, y_val = val_df[NUMERIC_FEATURES + CATEGORICAL_FEATURES], val_df[TARGET]

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)

    preds = pipeline.predict(X_val)

    print("Validation accuracy:", round(accuracy_score(y_val, preds), 4))
    print("\nClassification report:\n", classification_report(y_val, preds))
    print("Confusion matrix (rows=true, cols=pred), classes:", sorted(y_val.unique()))
    print(confusion_matrix(y_val, preds, labels=sorted(y_val.unique())))

    joblib.dump(pipeline, args.model_out)
    print(f"\nModel saved to: {args.model_out}")
    print(
        "\nNOTE: This RandomForest is a scikit-learn demo model to validate the "
        "pipeline end-to-end. For the actual on-device deployment described in "
        "the tech stack, retrain a TFLite-convertible model (e.g. a small dense "
        "neural network via TensorFlow/Keras) once real field data is available, "
        "then convert with tf.lite.TFLiteConverter."
    )


if __name__ == "__main__":
    main()
