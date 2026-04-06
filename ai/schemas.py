from datetime import datetime
from enum import Enum
from typing import List

from pydantic import BaseModel, ConfigDict, Field, field_validator


class RiskLevel(str, Enum):
    SAFE = "SAFE"
    WARNING = "WARNING"
    RISK = "RISK"


class AnalyzeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    features: List[float] = Field(
        ...,
        min_length=5,
        max_length=5,
        description="Normalized feature vector with 5 elements (0.0-1.0).",
        examples=[[0.12, 0.8, 0.45, 0.19, 0.72]],
    )
    source: str = Field(
        default="dashboard",
        min_length=2,
        max_length=64,
        pattern=r"^[a-zA-Z0-9_-]+$",
        description="Source system that generated the request.",
        examples=["dashboard"],
    )

    @field_validator("features")
    @classmethod
    def validate_feature_range(cls, value: List[float]) -> List[float]:
        if any(feature < 0 or feature > 1 for feature in value):
            raise ValueError("all feature values must be between 0 and 1")
        return value


class AnalyzeResponse(BaseModel):
    timestamp: datetime
    source: str
    score: float = Field(..., ge=0, le=1)
    risk: RiskLevel


class HealthResponse(BaseModel):
    status: str


class HomeResponse(BaseModel):
    status: str
    service: str


class MetricsResponse(BaseModel):
    service: str
    status: str
    events_total: int
    events_last_50: int
    risk_rate_last_50: float


class EventsResponse(BaseModel):
    events: List[AnalyzeResponse]


class RiskDistribution(BaseModel):
    SAFE: int
    WARNING: int
    RISK: int


class TimelineEvent(BaseModel):
    timestamp: datetime
    score: float
    risk: RiskLevel


class ReportResponse(BaseModel):
    window: int
    total_events: int
    avg_score: float
    risk_distribution: RiskDistribution
    timeline: List[TimelineEvent]
