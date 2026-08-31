"""
CREPISENSE risk-classifier training pipeline.

This implementation trains a TensorFlow model directly on the synthetic OA dataset.
The target is KL grade (0-4), which is then mapped to the app-facing risk labels:
Low = KL 0-1, Medium = KL 2, High = KL 3-4.
"""

import json
import pickle
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

BASE_DIR = Path(__file__).resolve().parent
DATA_PATH = BASE_DIR / "data" / "oa_risk_dataset.csv"
MODEL_PATH = BASE_DIR / "data" / "oa_risk_model.keras"
SCALER_PATH = BASE_DIR / "data" / "oa_risk_scaler.pkl"
FEATURES_PATH = BASE_DIR / "data" / "feature_columns.json"
ASSET_SCALER_PATH = BASE_DIR.parent / "mobile_app" / "assets" / "scaler_params.json"

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


def main():
    df = pd.read_csv(DATA_PATH)
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

    with open(SCALER_PATH, "wb") as scaler_file:
        pickle.dump(scaler, scaler_file)

    with open(FEATURES_PATH, "w", encoding="utf-8") as feature_file:
        json.dump(FEATURE_COLUMNS, feature_file)

    scaler_params = {
        "feature_columns": FEATURE_COLUMNS,
        "mean": scaler.mean_.astype(float).tolist(),
        "scale": scaler.scale_.astype(float).tolist(),
    }
    ASSET_SCALER_PATH.parent.mkdir(parents=True, exist_ok=True)
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
        epochs=200,
        batch_size=64,
        callbacks=[early_stop],
        verbose=1,
    )

    predictions = model.predict(X_val_scaled, verbose=0)
    predicted_labels = np.argmax(predictions, axis=1)

    val_accuracy = accuracy_score(y_val, predicted_labels)
    print(f"Validation accuracy: {val_accuracy:.4f}")
    print(confusion_matrix(y_val, predicted_labels))
    print(classification_report(y_val, predicted_labels, digits=4))

    model.save(MODEL_PATH)
    print(f"Saved trained Keras model to: {MODEL_PATH}")
    print(f"Saved scaler to: {SCALER_PATH}")
    print(f"Saved feature metadata to: {FEATURES_PATH}")
    print(f"Saved app scaler config to: {ASSET_SCALER_PATH}")
    print(f"Training epochs completed: {len(history.history['loss'])}")


if __name__ == "__main__":
    main()
