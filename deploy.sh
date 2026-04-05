#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[deploy] Deploying zSafeGuard..."

docker build -t zsafe-ai "$ROOT_DIR"

if command -v minikube >/dev/null 2>&1; then
  minikube start
else
  echo "[deploy] minikube not found; skipping cluster startup."
fi

if command -v kubectl >/dev/null 2>&1; then
  kubectl apply -f "$ROOT_DIR/k8s/"
else
  echo "[deploy] kubectl not found; skipping Kubernetes apply."
fi

uvicorn ai.main:app --reload &
UVICORN_PID=$!

(
  cd "$ROOT_DIR/dashboard"
  npm install
  npm start
) &
DASHBOARD_PID=$!

cleanup() {
  kill "$UVICORN_PID" "$DASHBOARD_PID" 2>/dev/null || true
}
trap cleanup EXIT

if command -v cloudflared >/dev/null 2>&1; then
  cloudflared tunnel --url http://localhost:8000
else
  echo "[deploy] cloudflared not found; services are running locally only."
  wait
fi
