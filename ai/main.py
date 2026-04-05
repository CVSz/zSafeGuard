import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from ai.ensemble import predict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("zsafeguard.ai")

API_KEY = os.getenv("API_KEY")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {"status": "ok"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/metrics")
def metrics():
    return {"service": "ai", "status": "ok"}


@app.post("/analyze")
def analyze(data: dict):
    features = data.get("features", [])
    logger.info("Analyze request received with %d features", len(features))
    if API_KEY:
        logger.debug("API key configured")
    return predict(features)
