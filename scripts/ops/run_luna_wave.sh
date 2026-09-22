#!/usr/bin/env bash
# composer-2.5 (cursor-agent) OSP generation wave over an --problems pool.
# Idempotent: each pass skips ids already in the dataset; a failed pass
# (any gate failures) sleeps and retries, so the wave runs problems down
# until only gate-hard ones remain.
#
# Usage: run_luna_wave.sh POOL SHARDS ITERS
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"
export OSP_COMPOSER_TIMEOUT="${OSP_COMPOSER_TIMEOUT:-300}"

POOL="${1:?usage: run_luna_wave.sh POOL SHARDS ITERS}"
SHARDS="${2:-2}"
ITERS="${3:-6}"
FAIL_SLEEP="${FAIL_SLEEP:-300}"

echo "[luna-wave] start $(date +%F\ %T) pool=$POOL shards=$SHARDS iters=$ITERS"
for i in $(seq 1 "$ITERS"); do
    echo "[luna-wave] iter $i/$ITERS $(date +%T)"
    pids=()
    for s in $(seq 0 $((SHARDS - 1))); do
        python3 scripts/gen/osp_luna_generate.py \
            --problems "$POOL" --shard "$s" --shards "$SHARDS" \
            >>"archive/2026-09/data_logs/osp_luna_shard${s}.log" 2>&1 &
        pids+=($!)
    done
    failed=0
    for p in "${pids[@]}"; do
        wait "$p" || failed=1
    done
    n=$(wc -l < data/osp_dataset.jsonl)
    echo "[luna-wave] iter $i done failed=$failed dataset_lines=$n"
    if [[ "$failed" == "0" ]]; then
        echo "[luna-wave] all shards clean after $i iters"
        break
    fi
    if [[ "$i" -lt "$ITERS" ]]; then
        sleep "$FAIL_SLEEP"
    fi
done
echo "[luna-wave] done $(date +%F\ %T)"
