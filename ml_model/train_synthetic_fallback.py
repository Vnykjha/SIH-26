"""
Synthetic fallback training pipeline for the OA screening app.
This script trains a KL-grade model using the Claude-generated synthetic dataset
and writes the artifacts expected by the mobile app.
"""

import json
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

BASE_DIR = Path(__file__).resolve().parent
ROOT_DIR = BASE_DIR.parent
DATASET_PATH = ROOT_DIR / "claude gen files" / "synthetic_knee_oa_dataset.csv"
MODEL_PATH = BASE_DIR / "data" / "oa_risk_model.keras"
SCALER_PATH = BASE_DIR / "data" / "oa_risk_scaler.pkl"
FEATURES_PATH = BASE_DIR / "data" / "feature_columns.json"
ASSET_SCALER_PATH = ROOT_DIR / "mobile_app" / "assets" / "scaler_params.json"
ASSET_MODEL_PATH = ROOT_DIR / "mobile_app" / "assets" / "model.tflite"

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


def normalize_dataset(df: pd.DataFrame) -> pd.DataFrame:
    normalized = df.copy()

    if "kl_grade" not in normalized.columns and "KL_grade" in normalized.columns:
        normalized["kl_grade"] = normalized["KL_grade"].astype(int)

    if "sex_code" not in normalized.columns:
        if "sex" in normalized.columns:
            sex_map = {"male": 0, "female": 1, "M": 0, "F": 1, "other": 2, "Other": 2}
            normalized["sex_code"] = normalized["sex"].map(sex_map).fillna(2)
        elif "sex_code" in normalized.columns:
            normalized["sex_code"] = normalized["sex_code"].astype(int)
        else:
            normalized["sex_code"] = 0

    if "bmi" not in normalized.columns:
        if "BMI" in normalized.columns:
            normalized["bmi"] = normalized["BMI"].astype(float)
        elif {"height_cm", "weight_kg"}.issubset(normalized.columns):
            normalized["bmi"] = normalized["weight_kg"] / ((normalized["height_cm"] / 100.0) ** 2)
        else:
            normalized["bmi"] = 25.0

    if "prior_injury" not in normalized.columns:
        if "prior_injury_history" in normalized.columns:
            normalized["prior_injury"] = normalized["prior_injury_history"].astype(str).str.lower().isin(["yes", "true", "1", "y"]).astype(int)
        else:
            normalized["prior_injury"] = np.zeros(len(normalized), dtype=int)

    if "womac_pain" not in normalized.columns and "knee_pain_score" in normalized.columns:
        normalized["womac_pain"] = normalized["knee_pain_score"].astype(float)
    if "womac_stiffness" not in normalized.columns and "stiffness_score" in normalized.columns:
        normalized["womac_stiffness"] = normalized["stiffness_score"].astype(float)
    if "womac_function" not in normalized.columns and "functional_limit_score" in normalized.columns:
        normalized["womac_function"] = normalized["functional_limit_score"].astype(float)

    if "duration_sec" not in normalized.columns and "total_time" in normalized.columns:
        normalized["duration_sec"] = normalized["total_time"].astype(float)
    if "peak_accel" not in normalized.columns and "max_acceleration" in normalized.columns:
        normalized["peak_accel"] = normalized["max_acceleration"].astype(float)
    if "accel_variance" not in normalized.columns:
        if {"max_acceleration", "min_acceleration"}.issubset(normalized.columns):
            normalized["accel_variance"] = (normalized["max_acceleration"] - normalized["min_acceleration"]).abs().astype(float)
        else:
            normalized["accel_variance"] = 0.0
    if "cadence_cps" not in normalized.columns:
        if "average_velocity" in normalized.columns and "duration_sec" in normalized.columns:
            normalized["cadence_cps"] = normalized["average_velocity"] / normalized["duration_sec"].replace({0: np.nan})
            normalized["cadence_cps"] = normalized["cadence_cps"].fillna(0.0)
        else:
            normalized["cadence_cps"] = 0.0
    if "kinetic_energy" not in normalized.columns and "average_power" in normalized.columns:
        normalized["kinetic_energy"] = normalized["average_power"].astype(float)

    for column in FEATURE_COLUMNS + ["kl_grade"]:
        if column in normalized.columns:
            normalized[column] = pd.to_numeric(normalized[column], errors="coerce").fillna(0)

    return normalized


def main():
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Synthetic dataset not found at {DATASET_PATH}")

    df = pd.read_csv(DATASET_PATH)
    df = normalize_dataset(df)

    if "kl_grade" not in df.columns:
        raise ValueError("Dataset must include kl_grade before training.")

    X = df[FEATURE_COLUMNS].astype(np.float32).to_numpy()
    y = df["kl_grade"].astype(np.int32).to_numpy()

    X_train, X_val, y_train, y_val = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=42,
        stratify=y,
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    ASSET_MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)

    with open(SCALER_PATH, "wb") as scaler_file:
        import pickle
        pickle.dump(scaler, scaler_file)

    with open(FEATURES_PATH, "w", encoding="utf-8") as feature_file:
        json.dump(FEATURE_COLUMNS, feature_file)

    scaler_params = {
        "feature_columns": FEATURE_COLUMNS,
        "mean": scaler.mean_.astype(float).tolist(),
        "scale": scaler.scale_.astype(float).tolist(),
    }
    with open(ASSET_SCALER_PATH, "w", encoding="utf-8") as asset_file:
        json.dump(scaler_params, asset_file)

    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(X_train.shape[1],)),
        tf.keras.layers.Dense(128, activation="relu"),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.20),
        tf.keras.layers.Dense(64, activation="relu"),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.15),
        tf.keras.layers.Dense(5, activation="softmax", name="kl_outputs"),
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"],
    )

    early_stop = tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy",
        patience=15,
        restore_best_weights=True,
    )

    history = model.fit(
        X_train_scaled,
        y_train,
        validation_data=(X_val_scaled, y_val),
        epochs=120,
        batch_size=64,
        callbacks=[early_stop],
        verbose=0,
    )

    predictions = model.predict(X_val_scaled, verbose=0)
    predicted_labels = np.argmax(predictions, axis=1)

    val_accuracy = accuracy_score(y_val, predicted_labels)
    print(f"Validation accuracy: {val_accuracy:.4f}")
    print(confusion_matrix(y_val, predicted_labels))
    print(classification_report(y_val, predicted_labels, digits=4))

    model.save(MODEL_PATH)
    print(f"Saved Keras model to: {MODEL_PATH}")
    print(f"Saved scaler to: {SCALER_PATH}")
    print(f"Saved feature metadata to: {FEATURES_PATH}")
    print(f"Saved app scaler config to: {ASSET_SCALER_PATH}")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float32]
    tflite_model = converter.convert()
    ASSET_MODEL_PATH.write_bytes(tflite_model)
    print(f"Saved TFLite model to: {ASSET_MODEL_PATH}")
    print(f"Synthetic training epochs: {len(history.history['loss'])}")


if __name__ == "__main__":
    main()
