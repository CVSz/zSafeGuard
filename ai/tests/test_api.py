import json
import multiprocessing
import socket
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import pytest
import uvicorn

from ai import main


HOST = "127.0.0.1"
PORT = 18000
BASE_URL = f"http://{HOST}:{PORT}"


def setup_function():
    main.risk_events.clear()


def _run_server():
    uvicorn.run("ai.main:app", host=HOST, port=PORT, log_level="error")


def _wait_for_server(timeout=8):
    start = time.time()
    while time.time() - start < timeout:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            if sock.connect_ex((HOST, PORT)) == 0:
                return
        time.sleep(0.1)
    raise RuntimeError("Server did not start in time")


def _request(method, path, payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = Request(
        f"{BASE_URL}{path}",
        data=data,
        method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urlopen(req, timeout=5) as response:
            body = response.read().decode("utf-8")
            return response.status, json.loads(body) if body else {}
    except HTTPError as exc:
        body = exc.read().decode("utf-8")
        return exc.code, json.loads(body) if body else {}


@pytest.fixture(scope="module")
def live_server():
    proc = multiprocessing.Process(target=_run_server, daemon=True)
    proc.start()
    _wait_for_server()
    yield
    proc.terminate()
    proc.join(timeout=3)


def test_analyze_request_model_validation():
    req = main.AnalyzeRequest(features=[0.2, 0.3, 0.4, 0.5, 0.6], source="unit_test")
    assert req.source == "unit_test"

    with pytest.raises(Exception):
        main.AnalyzeRequest(features=[1.5, 0.2, 0.3, 0.4, 0.5], source="bad")


def test_analyze_success_and_event_capture(live_server):
    status, body = _request(
        "POST",
        "/analyze",
        {"features": [0.2, 0.4, 0.6, 0.8, 0.9], "source": "integration_test"},
    )

    assert status == 200
    assert body["source"] == "integration_test"
    assert body["risk"] in {"SAFE", "WARNING", "RISK"}

    events_status, events = _request("GET", "/events?limit=1")
    assert events_status == 200
    assert len(events["events"]) == 1


def test_validation_errors(live_server):
    status, body = _request(
        "POST",
        "/analyze",
        {"features": [0.2, 0.4, 2.1, 0.8, 0.9], "source": "integration_test"},
    )
    assert status == 422
    assert any("between 0 and 1" in item["msg"] for item in body["detail"])

    status_events, _ = _request("GET", "/events?limit=999")
    assert status_events == 422

    status_report, _ = _request("GET", "/report?window=2")
    assert status_report == 422

    status_stream, _ = _request("GET", "/stream?interval_seconds=0.1")
    assert status_stream == 422


def test_report_and_metrics(live_server):
    for features in (
        [0.1, 0.2, 0.3, 0.4, 0.5],
        [0.2, 0.3, 0.4, 0.5, 0.6],
        [0.3, 0.4, 0.5, 0.6, 0.7],
    ):
        _request("POST", "/analyze", {"features": features, "source": "test"})

    report_status, report = _request("GET", "/report?window=5")
    assert report_status == 200
    assert report["total_events"] >= 3

    metrics_status, metrics = _request("GET", "/metrics")
    assert metrics_status == 200
    assert metrics["events_total"] >= 3
