#!/usr/bin/env bash
# CI shard for the `refactor` agent-task pool: validate this shard's tasks
# (starter works+unidiomatic, reference works+idiomatic, mutants killed)
# -> $OUT/refactor_results.jsonl
set -uo pipefail
cd "$GITHUB_WORKSPACE"
.venv/bin/python scripts/agent_tasks/refactor_build.py validate \
  --shard "$SHARD/$NSHARDS" --out "$OUT" ${REFACTOR_ONLY:+--only "$REFACTOR_ONLY"} ${REFACTOR_FORCE:+--force}
