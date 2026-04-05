#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$ROOT_DIR/install_full.sh"

if command -v minikube >/dev/null 2>&1; then
  echo "[install_ultimate] Starting minikube cluster..."
  minikube start
else
  echo "[install_ultimate] minikube not found; skipping local cluster startup."
fi

echo "[install_ultimate] Applying Kubernetes manifests..."
kubectl apply -f "$ROOT_DIR/k8s/"

echo "[install_ultimate] Ultimate setup complete."
