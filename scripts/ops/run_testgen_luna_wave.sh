#!/usr/bin/env bash
# Run osp_minimax_testgen 6-way shard slices at 3-way Codex concurrency:
# shards 0-2 in parallel, then 3-5. Codex (pi CLI, gpt-5.6-luna) starves
# past OSP_TESTGEN_TIMEOUT at 6-way concurrency; 3 fits.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"
export OSP_TESTGEN_MODEL="${OSP_TESTGEN_MODEL:-pi:gpt-5.6-luna}"
export OSP_TESTGEN_TIMEOUT="${OSP_TESTGEN_TIMEOUT:-300}"

wave() {
    local wave_n="$1"; shift
    local pids=()
    for s in "$@"; do
        bash scripts/ops/retry_osp_testgen.sh "$s" 6 10 \
            >>"archive/2026-09/data_logs/osp_testgen_shard${s}.log" 2>&1 &
        pids+=($!)
        echo "[wave${wave_n}] launched shard $s pid=$!"
    done
    for p in "${pids[@]}"; do wait "$p"; echo "[wave${wave_n}] pid $p exit=$?"; done
}

echo "[wave] start $(date +%F\ %T) model=$OSP_TESTGEN_MODEL timeout=$OSP_TESTGEN_TIMEOUT"
wave 1 0 1 2
wave 2 3 4 5
echo "[wave] done $(date +%F\ %T)"
