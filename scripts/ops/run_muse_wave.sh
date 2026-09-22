#!/usr/bin/env bash
# muse-spark-1.2-contributor-free OSP generation wave over an --problems pool.
#
# The zen contributor-free backend has outage windows (hard 500 walls), so the
# loop tolerates full-failure passes: each pass fast-fails (500s return in
# ~1s) and sleeps OUTAGE_SLEEP before retrying, resuming for free off the
# dataset's existing-id check. When the backend recovers, passes start
# landing records and the loop runs them down.
#
# Usage: run_muse_wave.sh POOL SHARDS ITERS
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"
export OSP_MUSE_TRIES="${OSP_MUSE_TRIES:-6}"
OUTAGE_SLEEP="${OUTAGE_SLEEP:-600}"

POOL="${1:?usage: run_muse_wave.sh POOL SHARDS ITERS}"
SHARDS="${2:-2}"
ITERS="${3:-20}"

wave() {
    local iter="$1"; shift
    local pids=()
    local s
    for s in $(seq 0 $((SHARDS - 1))); do
        (
            python3 scripts/gen/osp_muse_generate.py \
                --problems "$POOL" --shard "$s" --shards "$SHARDS" \
                >>"archive/2026-09/data_logs/osp_muse_shard${s}.log" 2>&1
            echo "$?" > "/tmp/muse_shard${s}_rc"
        ) &
        pids+=($!)
    done
    local failed=0
    for p in "${pids[@]}"; do
        wait "$p"
    done
    for s in $(seq 0 $((SHARDS - 1))); do
        rc=$(cat "/tmp/muse_shard${s}_rc" 2>/dev/null || echo 1)
        if [[ "$rc" != "0" ]]; then failed=1; fi
    done
    echo "$failed"
}

echo "[muse-wave] start $(date +%F\ %T) pool=$POOL shards=$SHARDS iters=$ITERS tries=$OSP_MUSE_TRIES"
for i in $(seq 1 "$ITERS"); do
    echo "[muse-wave] iter $i/$ITERS $(date +%T)"
    failed=$(wave "$i")
    n=$(wc -l < data/osp_dataset.jsonl)
    echo "[muse-wave] iter $i done failed=$failed dataset_lines=$n"
    if [[ "$failed" == "0" ]]; then
        echo "[muse-wave] all shards clean after $i iters"
        break
    fi
    if [[ "$i" -lt "$ITERS" ]]; then
        tail -1 "archive/2026-09/data_logs/osp_muse_shard0.log" | grep -q "http 500" && sleep "$OUTAGE_SLEEP"
    fi
done
echo "[muse-wave] done $(date +%F\ %T)"
