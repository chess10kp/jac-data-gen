#!/usr/bin/env bash
# CI shard for the `refactor` agent-task pool: validate this shard's tasks
# (starter works+unidiomatic, reference works+idiomatic, mutants killed)
# -> $OUT/refactor_results.jsonl. Optional .ci/agent-tasks/refactor.only = comma list of ids.
set -uo pipefail
ulimit -c 0
cd "$GITHUB_WORKSPACE"
ONLY="${REFACTOR_ONLY:-}"
[ -z "$ONLY" ] && [ -s .ci/agent-tasks/refactor.only ] && ONLY="$(tr -d ' \n' < .ci/agent-tasks/refactor.only)"
.venv/bin/python scripts/agent_tasks/refactor_build.py validate \
  --shard "$SHARD/$NSHARDS" --out "$OUT" ${ONLY:+--only "$ONLY"} --force
