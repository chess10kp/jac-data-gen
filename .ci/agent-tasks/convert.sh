#!/usr/bin/env bash
# CI shard for the `convert` agent-task kind (Python/FARM -> idiomatic Jac):
# validate this shard's tasks (starter fails; reference passes check/fidelity/test[/start];
# body-stubbed reference and every negative are killed; stable) -> $OUT/convert_results.jsonl
set -uo pipefail
cd "$GITHUB_WORKSPACE"
RUN_ID="${GITHUB_RUN_ID:-ci}"
.venv/bin/python scripts/agent_tasks/convert_build.py validate \
  --shard "$SHARD/$NSHARDS" --out "$OUT" --run-id "$RUN_ID" ${CONVERT_ONLY:+--only "$CONVERT_ONLY"} ${CONVERT_FORCE:+--force}
