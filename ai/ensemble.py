import logging
from functools import lru_cache
from pathlib import Path

import joblib

MODEL_DIR = Path(__file__).resolve().parent / "model"
logger = logging.getLogger("zsafeguard.ai.ensemble")


@lru_cache(maxsize=1)
def _load_models():
    xgb_model = joblib.load(MODEL_DIR / "xgb.pkl")
    nn_model = joblib.load(MODEL_DIR / "nn.pkl")
    return xgb_model, nn_model


def _fallback_predict(features):
    score = sum(features) / len(features)
    return {
        "score": float(score),
        "risk": "RISK" if score > 0.75 else "WARNING" if score > 0.5 else "SAFE",
    }


def predict(features):
    try:
        xgb_model, nn_model = _load_models()
        x = xgb_model.predict_proba([features])[0][1]
        n = nn_model.predict([features])[0]
        score = (x * 0.6) + (n * 0.4)
        return {
            "score": float(score),
            "risk": "RISK" if score > 0.75 else "WARNING" if score > 0.5 else "SAFE",
        }
    except Exception as exc:  # noqa: BLE001
        logger.warning("Failed to load/use model artifacts, using fallback predictor: %s", exc)
        return _fallback_predict(features)
