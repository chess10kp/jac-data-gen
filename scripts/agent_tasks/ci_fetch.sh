#!/usr/bin/env bash
# Wait for the latest agent-tasks/<kind> run and download all shard outputs to
# runs/ci/<kind>/<run_id>/ (one dir per shard).
# Usage: ci_fetch.sh <kind> [run_id]
set -euo pipefail
KIND="$1"; BR="agent-tasks/$KIND"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN="${2:-$(gh run list -b "$BR" -L 1 --json databaseId -q '.[0].databaseId')}"
gh run watch "$RUN" --exit-status --interval 30 >/dev/null || echo "run $RUN finished with failures (downloading what exists)" >&2
DEST="$REPO/runs/ci/$KIND/$RUN"
mkdir -p "$DEST"
gh run download "$RUN" -D "$DEST"
echo "$DEST"
