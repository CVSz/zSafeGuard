from pathlib import Path

import joblib

MODEL_DIR = Path(__file__).resolve().parent / "model"

xgb = joblib.load(MODEL_DIR / "xgb.pkl")
nn = joblib.load(MODEL_DIR / "nn.pkl")


def predict(features):
    x = xgb.predict_proba([features])[0][1]
    n = nn.predict([features])[0]

    score = (x * 0.6) + (n * 0.4)

    return {
        "score": float(score),
        "risk": "RISK" if score > 0.75 else "WARNING" if score > 0.5 else "SAFE",
    }
