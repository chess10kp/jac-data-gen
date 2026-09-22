#!/usr/bin/env bash
# Outer retry loop for osp_minimax_testgen.py (same contract as
# retry_osp_minimax.sh): re-runs until the inner script exits 0 (no
# harness-broken records left) or --max-iters is exhausted. Results sidecar
# is id-idempotent, so each iter only pays for untested records.
#
# Usage: retry_osp_testgen.sh SHARD SHARDS [MAX_ITERS] [-- args...]
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

SHARD="${1:?usage: retry_osp_testgen.sh SHARD SHARDS [MAX_ITERS] [-- args...]}"
SHARDS="${2:?usage: ...}"
MAX_ITERS="${3:-10}"
shift 3
EXTRA_ARGS=("$@")
MIN_FREE_GB="${MIN_FREE_GB:-8}"
LOG="archive/2026-09/data_logs/osp_testgen_shard${SHARD}.log"

echo "[retry] shard=$SHARD/$SHARDS max_iters=$MAX_ITERS extra=${EXTRA_ARGS[*]:-}"
echo "[retry] log -> $LOG"
for i in $(seq 1 "$MAX_ITERS"); do
    avail=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
    if (( avail < MIN_FREE_GB )); then
        echo "[retry] low disk: ${avail}G free < ${MIN_FREE_GB}G; sleeping 300s"
        sleep 300
        continue
    fi
    echo "[retry] iter $i/$MAX_ITERS $(date +%H:%M:%S)"
    python3 scripts/gen/osp_minimax_testgen.py \
        --shard "$SHARD" --shards "$SHARDS" \
        "${EXTRA_ARGS[@]}" 2>&1 | tee -a "$LOG"
    rc=${PIPESTATUS[0]}
    n_after=$(wc -l < data/osp_test_results.jsonl 2>/dev/null || echo 0)
    echo "[retry] iter $i exit=$rc results_lines=$n_after"
    if [[ $rc -eq 0 ]]; then
        echo "[retry] shard $SHARD complete after $i iters"
        exit 0
    fi
done

echo "[retry] shard $SHARD hit MAX_ITERS=$MAX_ITERS without reaching 0 harness failures"
exit 1
