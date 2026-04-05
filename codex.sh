#!/bin/bash
# ============================================================
# zLinebot Codex Master Full Meta Final Release
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
  log "[Codex] Running Basic Installation..."
  run_script install.sh
  ;;
full)
  log "[Codex] Running Full-stack Installation..."
  run_script install_full.sh
  ;;
ultimate)
  log "[Codex] Running Ultimate Deployment..."
  run_script install_ultimate.sh
  ;;
orchestrator)
  log "[Codex] Running Master Orchestrator..."
  run_script zlinebot-master-orchestrator.sh
  ;;
release)
  log "[Codex] Executing Final Release Workflow..."
  run_script install_ultimate.sh
  run_script zlinebot-master-orchestrator.sh
  log "[Codex] Release build complete. Artifacts logged in ${LOGFILE}"
  ;;
*)
  usage
  exit 1
  ;;
esac

log "[Codex] Process finished successfully."
