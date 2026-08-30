import os
import time
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["method", "endpoint"]
)

@app.before_request
def before_request():
    from flask import g
    g.start_time = time.time()

@app.after_request
def after_request(response):
    from flask import request, g
    elapsed = time.time() - getattr(g, "start_time", time.time())
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.method, request.path).observe(elapsed)
    return response

@app.get("/")
def index():
    return jsonify(
        service="octabyte-devops-app",
        environment=os.getenv("APP_ENV", "local"),
        message="Application is running"
    )

@app.get("/health")
def health():
    return jsonify(status="healthy"), 200

@app.get("/ready")
def ready():
    return jsonify(status="ready"), 200

@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
