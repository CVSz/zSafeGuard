import asyncio
import json
import logging
import os
from collections import Counter, deque
from datetime import datetime, timezone
from typing import Annotated

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from ai.ensemble import predict
from ai.schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    EventsResponse,
    HealthResponse,
    HomeResponse,
    MetricsResponse,
    ReportResponse,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("zsafeguard.ai")

API_KEY = os.getenv("API_KEY")
MAX_EVENT_HISTORY = int(os.getenv("MAX_EVENT_HISTORY", "500"))

app = FastAPI(
    title="zSafeGuard AI",
    version="1.1.0",
    description=(
        "Risk analysis API for zSafeGuard. The API accepts a normalized "
        "feature vector and returns score-based risk classifications."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

risk_events = deque(maxlen=MAX_EVENT_HISTORY)


@app.get("/", response_model=HomeResponse, tags=["system"])
def home():
    return {"status": "ok", "service": "zsafeguard-ai"}


@app.get("/health", response_model=HealthResponse, tags=["system"])
def health():
    return {"status": "ok"}


@app.get("/metrics", response_model=MetricsResponse, tags=["analytics"])
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


@app.get("/events", response_model=EventsResponse, tags=["analytics"])
def events(limit: Annotated[int, Query(ge=1, le=200)] = 20):
    return {"events": list(risk_events)[-limit:]}


@app.get("/report", response_model=ReportResponse, tags=["analytics"])
def report(window: Annotated[int, Query(ge=5, le=MAX_EVENT_HISTORY)] = 100):
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


@app.post("/analyze", response_model=AnalyzeResponse, tags=["inference"])
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


@app.get("/stream", tags=["streaming"])
async def stream(interval_seconds: Annotated[float, Query(ge=0.5, le=10)] = 2.0):
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
