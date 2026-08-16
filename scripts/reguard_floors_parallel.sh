#!/usr/bin/env bash
# Launch N parallel reguard shards (disjoint embedded-PG pools).
# Usage: scripts/reguard_floors_parallel.sh [shards] [workers_per_shard]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PY="${PY:-.venv/bin/python}"
SHARDS="${1:-4}"
WORKERS="${2:-4}"
LOG_DIR="$ROOT/data/reguard_shard_logs"
CKPT_DIR="$ROOT/data/reguard_checkpoints"
mkdir -p "$LOG_DIR" "$CKPT_DIR"

echo "=== $(date) reguard parallel: ${SHARDS} shards × ${WORKERS} workers ==="

# Stop any single-process reguard still running.
pkill -f 'scripts/reguard_floors.py' 2>/dev/null || true
sleep 2

for i in $(seq 0 $((SHARDS - 1))); do
  TMP="/tmp/reguard_pg_${i}"
  mkdir -p "$TMP"
  nohup env JAC_PROC_TIMEOUT=300 PYTHONUNBUFFERED=1 \
    "$PY" scripts/reguard_floors.py \
      --shard "$i" --shards "$SHARDS" \
      --workers "$WORKERS" \
      --shared-tmp "$TMP" \
      --checkpoint-dir "$CKPT_DIR" \
    >> "$LOG_DIR/shard_${i}.log" 2>&1 &
  echo "shard $i pid=$! tmp=$TMP log=$LOG_DIR/shard_${i}.log"
done

echo "Monitor: tail -f $LOG_DIR/shard_*.log"
echo "When all shards finish, merge: $PY scripts/reguard_floors.py --merge"
