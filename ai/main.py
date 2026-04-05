from fastapi import FastAPI
from ensemble import predict

app = FastAPI()


@app.get("/")
def home():
    return {"status": "ok"}


@app.post("/analyze")
def analyze(data: dict):
    features = data.get("features", [])
    return predict(features)
