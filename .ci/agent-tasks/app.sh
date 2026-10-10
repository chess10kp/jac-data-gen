#!/usr/bin/env bash
# CI shard for the `app` agent-task kind: validate tasks (reference passes every
# gate incl. `jac run --serve` HTTP smoke; bare starter fails) -> $OUT/results.jsonl
set -euo pipefail
cd "$GITHUB_WORKSPACE"
.venv/bin/python scripts/agent_tasks/app_build.py validate --shard "$SHARD/$NSHARDS" --out "$OUT" ${APP_FORCE:+--force}
