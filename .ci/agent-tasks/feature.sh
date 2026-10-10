#!/usr/bin/env bash
# Validate `feature` agent tasks: reference green + passes hidden tests/regression;
# starter green + passes regression, fails the new checks.
set -uo pipefail
cd "$GITHUB_WORKSPACE"
.venv/bin/python scripts/agent_tasks/feature_build.py validate --shard "$SHARD/$NSHARDS" --out "$GITHUB_WORKSPACE/$OUT"
