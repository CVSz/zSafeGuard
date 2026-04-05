#!/bin/bash
# ============================================================
# Codex Master Full Meta Final Release
# Unified installer & orchestrator for all environments
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="${SCRIPT_DIR}/codex_release.log"
MODE="${1:-}"

usage() {
  echo "Usage: codex.sh {basic|full|ultimate|orchestrator|release}"
}

log() {
  local message="$1"
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$message" | tee -a "$LOGFILE"
}

require_command() {
  local cmd="$1"
  local err_message="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo >&2 "$err_message"
    exit 1
  fi
}

run_script() {
  local script_name="$1"
  local script_path="${SCRIPT_DIR}/${script_name}"

  if [[ ! -f "$script_path" ]]; then
    echo >&2 "Required script not found: ${script_name}"
    exit 1
  fi

  bash "$script_path" | tee -a "$LOGFILE"
}

if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi

# --- Environment Validation ---
log "[Codex] Validating environment..."
require_command docker "Docker not installed. Aborting."
require_command node "Node.js not installed. Aborting."

if ! command -v kubectl >/dev/null 2>&1; then
  log "[Codex] Warning: Kubernetes not found, skipping cluster orchestration."
fi

# --- Mode Selection ---
case "$MODE" in
  basic)
    echo "[Codex] Running Basic Installation..." | tee -a $LOGFILE
    bash install.sh | tee -a $LOGFILE
    ;;
  full)
    echo "[Codex] Running Full-stack Installation..." | tee -a $LOGFILE
    bash install_full.sh | tee -a $LOGFILE
    ;;
  ultimate)
    echo "[Codex] Running Ultimate Deployment..." | tee -a $LOGFILE
    
    ;;
  orchestrator)
    echo "[Codex] Running Master Orchestrator..." | tee -a $LOGFILE
    bash master-orchestrator.sh | tee -a $LOGFILE
    ;;
  release)
    echo "[Codex] Executing Final Release Workflow..." | tee -a $LOGFILE
    bash install_ultimate.sh | tee -a $LOGFILE
    bash master-orchestrator.sh | tee -a $LOGFILE
    echo "[Codex] Release build complete. Artifacts logged in $LOGFILE"
    ;;
  *)
    echo "Usage: codex.sh {basic|full|ultimate|orchestrator|release}"
    exit 1
    ;;
esac

log "[Codex] Process finished successfully."
