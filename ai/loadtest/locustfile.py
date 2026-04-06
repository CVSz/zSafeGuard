from locust import HttpUser, between, task


class RiskApiUser(HttpUser):
    wait_time = between(0.1, 0.5)

    @task(6)
    def analyze(self):
        self.client.post(
            "/analyze",
            json={"features": [0.12, 0.8, 0.45, 0.19, 0.72], "source": "loadtest"},
            name="POST /analyze",
        )

    @task(2)
    def metrics(self):
        self.client.get("/metrics", name="GET /metrics")

    @task(1)
    def report(self):
        self.client.get("/report?window=50", name="GET /report")

    @task(1)
    def events(self):
        self.client.get("/events?limit=20", name="GET /events")
