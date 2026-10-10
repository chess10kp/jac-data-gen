#!/usr/bin/env bash
# CI shard for the `debug` agent-task pool: validate this shard's injected-bug tasks
# (reference passes all gates, starter compiles but fails hidden tests, each bug
# killed, fidelity rejects stubs, visible repro fails->passes) -> $OUT/debug_results.jsonl
set -uo pipefail
cd "$GITHUB_WORKSPACE"
export JAC_TEST_JOBS=0 FIX_SYM_JOBS=4
.venv/bin/python scripts/agent_tasks/debug_build.py validate \
  --shard "$SHARD/$NSHARDS" --out "$OUT" ${DEBUG_ONLY:+--only "$DEBUG_ONLY"}
