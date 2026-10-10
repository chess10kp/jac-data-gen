#!/usr/bin/env bash
# fix kind: FIX_STAGE=candidates (default) proposes+validates+calibrates units;
# FIX_STAGE=validate re-verifies the committed pool in data/agent_tasks/fix.
set -euo pipefail
cd "$GITHUB_WORKSPACE"
STAGE="$(cat .ci/agent-tasks/fix.stage 2>/dev/null || echo candidates)"
export FIX_SYM_JOBS=4
.venv/bin/python scripts/agent_tasks/fix_build.py "$STAGE" --shard "$SHARD/$NSHARDS" --out "$OUT" --nonsf data/agent_tasks/fix/_src/nonsf.tar.gz
