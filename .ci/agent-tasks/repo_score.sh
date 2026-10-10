#!/usr/bin/env bash
# Repo-quality scoring shard: clone JacHacks repos, jac check (as-is / repaired / mech),
# code map + run/serve probes. Merged locally by repo_score.py merge.
set -uo pipefail
cd "$GITHUB_WORKSPACE"
git config --global advice.detachedHead false
.venv/bin/python scripts/agent_tasks/repo_score.py ci --shard "$SHARD/$NSHARDS" --out "$GITHUB_WORKSPACE/$OUT" --jobs 2
