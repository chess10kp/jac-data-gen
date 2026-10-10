#!/usr/bin/env bash
# testgen kind. Stage from .ci/agent-tasks/testgen.stage:
#   validate (default): run every candidate mutant against the oracle / reference /
#                       trivial / starter suites -> $OUT/testgen_results.jsonl
#   confirm:            end-to-end through testgen_grade.py with the frozen
#                       grader/mutants.jsonl (ref must pass, empty/trivial must fail)
set -uo pipefail
cd "$GITHUB_WORKSPACE"
STAGE="$(cat .ci/agent-tasks/testgen.stage 2>/dev/null || echo validate)"
mkdir -p "$OUT"
jac --version | tee "$OUT/jac_version_$SHARD.txt"
.venv/bin/python scripts/agent_tasks/testgen_build.py "$STAGE" \
  --shard "$SHARD/$NSHARDS" --out "$OUT" --jobs 4 ${TESTGEN_ONLY:+--only "$TESTGEN_ONLY"} 2>&1 | tee "$OUT/log_$SHARD.txt"
