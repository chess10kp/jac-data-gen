"""Resolve the jac binary for corpus pipeline scripts.

Pin order (first hit wins):
  1. $JAC_BIN            explicit override (pre-existing convention,
                         e.g. scripts/gen/repair_pass.py)
  2. vendor/jac/bin/jac  exact compiler copy this corpus was gated with
                         (see vendor/jac/VERSION)
  3. shutil.which("jac") PATH fallback

Rationale: gates/codemod/packers key off exact diagnostics (E0013/E0014/
E0048). An in-place `jac` upgrade must not silently re-shuffle corpus
tiers; scripts opt back into PATH behavior only if the vendored copy is
deleted.
"""
from __future__ import annotations

import os
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VENDORED = REPO / "vendor" / "jac" / "bin" / "jac"


def resolve_jac() -> str:
    """Return the jac executable path this script must gate against."""
    override = os.environ.get("JAC_BIN")
    if override:
        return override
    if VENDORED.is_file() and os.access(VENDORED, os.X_OK):
        return str(VENDORED)
    found = shutil.which("jac")
    if found:
        return found
    return "jac"
