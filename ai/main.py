import asyncio
import json
import logging
import os
from collections import Counter, deque
from datetime import datetime, timezone
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from ai.ensemble import predict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("zsafeguard.ai")

API_KEY = os.getenv("API_KEY")
MAX_EVENT_HISTORY = int(os.getenv("MAX_EVENT_HISTORY", "500"))

app = FastAPI(title="zSafeGuard AI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

risk_events = deque(maxlen=MAX_EVENT_HISTORY)


class AnalyzeRequest(BaseModel):
    features: List[float] = Field(..., min_length=5, max_length=5)
    source: str = Field(default="dashboard", max_length=64)


@app.get("/")
def home():
    return {"status": "ok", "service": "zsafeguard-ai"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/metrics")
def metrics():
    total = len(risk_events)
    recent = list(risk_events)[-50:]
    risk_count = sum(1 for item in recent if item["risk"] == "RISK")
    return {
        "service": "ai",
        "status": "ok",
        "events_total": total,
        "events_last_50": len(recent),
        "risk_rate_last_50": round((risk_count / len(recent)), 3) if recent else 0,
    }


@app.get("/events")
def events(limit: int = 20):
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 200")
    return {"events": list(risk_events)[-limit:]}


@app.get("/report")
def report(window: int = 100):
    if window < 5 or window > MAX_EVENT_HISTORY:
        raise HTTPException(status_code=400, detail=f"window must be between 5 and {MAX_EVENT_HISTORY}")

    snapshot = list(risk_events)[-window:]
    if not snapshot:
        return {
            "window": window,
            "total_events": 0,
            "avg_score": 0,
            "risk_distribution": {"SAFE": 0, "WARNING": 0, "RISK": 0},
            "timeline": [],
        }

    distribution = Counter(item["risk"] for item in snapshot)
    timeline = [
        {"timestamp": event["timestamp"], "score": event["score"], "risk": event["risk"]}
        for event in snapshot[-20:]
    ]

    return {
        "window": window,
        "total_events": len(snapshot),
        "avg_score": round(sum(item["score"] for item in snapshot) / len(snapshot), 4),
        "risk_distribution": {
            "SAFE": distribution.get("SAFE", 0),
            "WARNING": distribution.get("WARNING", 0),
            "RISK": distribution.get("RISK", 0),
        },
        "timeline": timeline,
    }


@app.post("/analyze")
def analyze(data: AnalyzeRequest):
    logger.info("Analyze request received with %d features", len(data.features))
    if API_KEY:
        logger.debug("API key configured")

    result = predict(data.features)
    event = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "source": data.source,
        **result,
    }
    risk_events.append(event)
    return event


@app.get("/stream")
async def stream(interval_seconds: float = 2.0):
    if interval_seconds < 0.5 or interval_seconds > 10:
        raise HTTPException(status_code=400, detail="interval_seconds must be between 0.5 and 10")

    async def event_generator():
        last_seen = None
        while True:
            latest = risk_events[-1] if risk_events else None
            if latest and latest != last_seen:
                payload = {"type": "risk_event", "payload": latest}
                yield f"data: {json.dumps(payload)}\n\n"
                last_seen = latest
            else:
                heartbeat = {"type": "heartbeat", "payload": {"at": datetime.now(timezone.utc).isoformat()}}
                yield f"data: {json.dumps(heartbeat)}\n\n"
            await asyncio.sleep(interval_seconds)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
