#!/bin/bash
# ============================================================
# zLinebot Codex Master Full Meta Final Release
# Unified installer & orchestrator for all environments
# ============================================================

set -e

MODE=$1
LOGFILE="codex_release.log"

# --- Environment Validation ---
echo "[Codex] Validating environment..." | tee -a $LOGFILE
command -v docker >/dev/null 2>&1 || { echo >&2 "Docker not installed. Aborting."; exit 1; }
command -v node >/dev/null 2>&1 || { echo >&2 "Node.js not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || echo "[Codex] Warning: Kubernetes not found, skipping cluster orchestration." | tee -a $LOGFILE

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
    bash install_ultimate.sh | tee -a $LOGFILE
    ;;
  orchestrator)
    echo "[Codex] Running Master Orchestrator..." | tee -a $LOGFILE
    bash zlinebot-master-orchestrator.sh | tee -a $LOGFILE
    ;;
  release)
    echo "[Codex] Executing Final Release Workflow..." | tee -a $LOGFILE
    bash install_ultimate.sh | tee -a $LOGFILE
    bash zlinebot-master-orchestrator.sh | tee -a $LOGFILE
    echo "[Codex] Release build complete. Artifacts logged in $LOGFILE"
    ;;
  *)
    echo "Usage: codex.sh {basic|full|ultimate|orchestrator|release}"
    exit 1
    ;;
esac

echo "[Codex] Process finished successfully." | tee -a $LOGFILE
