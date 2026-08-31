"""
Export the trained Keras KL-grade model to TensorFlow Lite for the Flutter app.
"""

from pathlib import Path

import tensorflow as tf

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "data" / "oa_risk_model.keras"
TARGET_PATH = BASE_DIR.parent / "mobile_app" / "assets" / "model.tflite"


def main():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Training artifact not found at {MODEL_PATH}. Run train.py first."
        )

    model = tf.keras.models.load_model(MODEL_PATH)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float32]

    tflite_model = converter.convert()
    TARGET_PATH.parent.mkdir(parents=True, exist_ok=True)
    TARGET_PATH.write_bytes(tflite_model)

    print(f"Saved TFLite model to: {TARGET_PATH}")
    print(f"Model size: {TARGET_PATH.stat().st_size} bytes")


if __name__ == "__main__":
    main()
