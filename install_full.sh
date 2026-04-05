#!/usr/bin/env bash
set -euo pipefail

bash "$(dirname "$0")/install.sh"

echo "[install_full] Building AI image..."
docker build -t zsafe-ai .

echo "[install_full] Full installation complete."
