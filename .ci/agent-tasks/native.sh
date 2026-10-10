#!/usr/bin/env bash
# CI shard for the `native` agent-task pool: validate this shard's tasks
# (reference/alts/mutants/determinism/run/start gates) -> $OUT/native_results.jsonl
set -uo pipefail
export NATIVE_LOG_DIR="$GITHUB_WORKSPACE/$OUT/logs"
cd "$GITHUB_WORKSPACE"
.venv/bin/python scripts/agent_tasks/native_build.py validate \
  --shard "$SHARD/$NSHARDS" --out "$OUT" ${NATIVE_ONLY:+--only "$NATIVE_ONLY"}
