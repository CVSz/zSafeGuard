#!/bin/bash
set -euo pipefail
# ============================================================
# Codex Master Full Meta Final Release
# Unified installer & orchestrator for all environments
# ============================================================

readonly LOGFILE="codex_release.log"

usage() {
  echo "Usage: codex.sh {basic|full|ultimate|orchestrator|release}"
}

require_cmd() {
  local cmd="$1"
  local message="$2"
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$message" >&2
    exit 1
  }
}

run_step() {
  local script="$1"

  if [[ ! -f "$script" ]]; then
    echo "[Codex] Required script '$script' not found. Aborting." | tee -a "$LOGFILE"
    exit 1
  fi

  bash "$script" | tee -a "$LOGFILE"
}

main() {
  local mode="${1:-}"

  if [[ -z "$mode" ]]; then
    usage
    exit 1
  fi

  : >"$LOGFILE"

  echo "[Codex] Validating environment..." | tee -a "$LOGFILE"
  require_cmd "docker" "Docker not installed. Aborting."
  require_cmd "node" "Node.js not installed. Aborting."
  command -v kubectl >/dev/null 2>&1 || \
    echo "[Codex] Warning: Kubernetes not found, skipping cluster orchestration." | tee -a "$LOGFILE"

  case "$mode" in
    basic)
      echo "[Codex] Running Basic Installation..." | tee -a "$LOGFILE"
      run_step "install.sh"
      ;;
    full)
      echo "[Codex] Running Full-stack Installation..." | tee -a "$LOGFILE"
      run_step "install_full.sh"
      ;;
    ultimate)
      echo "[Codex] Running Ultimate Deployment..." | tee -a "$LOGFILE"
      run_step "install_ultimate.sh"
      ;;
    orchestrator)
      echo "[Codex] Running Master Orchestrator..." | tee -a "$LOGFILE"
      run_step "master-orchestrator.sh"
      ;;
    release)
      echo "[Codex] Executing Final Release Workflow..." | tee -a "$LOGFILE"
      run_step "install_ultimate.sh"
      run_step "master-orchestrator.sh"
      echo "[Codex] Release build complete. Artifacts logged in $LOGFILE" | tee -a "$LOGFILE"
      ;;
    *)
      usage
      exit 1
      ;;
  esac

  echo "[Codex] Process finished successfully." | tee -a "$LOGFILE"
}

main "$@"
