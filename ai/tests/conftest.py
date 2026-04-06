"""Pytest configuration for repository-local imports."""

from __future__ import annotations

import sys
from pathlib import Path


# Ensure imports like `from ai import ...` work when pytest is executed
# from inside the `ai/` directory (as done in CI).
REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))
