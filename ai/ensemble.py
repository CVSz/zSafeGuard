import joblib

xgb = joblib.load("model/xgb.pkl")
nn = joblib.load("model/nn.pkl")


def predict(features):
    x = xgb.predict_proba([features])[0][1]
    n = nn.predict([features])[0]

    score = (x * 0.6) + (n * 0.4)

    return {
        "score": float(score),
        "risk": "RISK" if score > 0.75 else "WARNING" if score > 0.5 else "SAFE",
    }
