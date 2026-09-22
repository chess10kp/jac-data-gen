#!/usr/bin/env bash
# Run one OSP generation batch: assign (if missing) → generate → validate manifest.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

BATCH="${1:?usage: run_osp_wave.sh BATCH}"
LIMIT="${2:-10}"

echo "=== OSP wave batch $BATCH (limit $LIMIT) ==="

if [[ ! -f "data/osp_lifts/assignments/issues_${BATCH}_assign.json" ]]; then
  python3 scripts/ops/make_assignments.py "$BATCH"
fi

python3 scripts/gen/osp_agent_generate.py --batch "$BATCH" --limit "$LIMIT"

python3 scripts/ops/sequential_validate_manifest.py "$BATCH" --append

python3 scripts/gen/pack_osp_lifts.py --trust-manifests

echo "=== batch $BATCH done ==="
