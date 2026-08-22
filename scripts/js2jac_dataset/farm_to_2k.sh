#!/usr/bin/env bash
# Loop the FARM pipeline (discover -> prep-refresh -> grind) until the master
# dataset reaches TARGET records (default 2000). Each round is fully
# resume/idempotent-safe; rounds that add 0 records AND discover 0 new model
# files stop the loop (source exhausted). Quota-shut rounds (discovery grew
# but master flat) are retried after a pause — farm composer has no canary,
# the loop is the retry.
# Usage: farm_to_2k.sh [target]     (env WORKERS passed to farm composer)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"

TARGET="${1:-2000}"
MODELS="scripts/js2jac_dataset/farm_models.jsonl"
LOG="data/farm_to_2k.log"
echo "=== farm_to_2k start $(date '+%F %T') target=$TARGET ===" >> "$LOG"

prev_master=0
prev_models=0
while :; do
  n=$(wc -l < data/farm_dataset.jsonl 2>/dev/null || echo 0)
  m=$(wc -l < "$MODELS" 2>/dev/null || echo 0)
  echo "[to2k] master=$n/$TARGET models=$m $(date '+%T')" >> "$LOG"
  if [ "$n" -ge "$TARGET" ]; then
    echo "[to2k] target reached" >> "$LOG"; break
  fi
  if [ "$n" -eq "$prev_master" ] && [ "$m" -eq "$prev_models" ]; then
    echo "[to2k] no progress and no new models — stopping (source exhausted)" >> "$LOG"
    break
  fi
  prev_master="$n"; prev_models="$m"
  WORKERS="${WORKERS:-3}" bash "$HERE/farm_full_run.sh" "$MODELS" 600 >> "$LOG" 2>&1
  sleep 300
done
final=$(wc -l < data/farm_dataset.jsonl 2>/dev/null || echo 0)
echo "=== farm_to_2k end $(date '+%F %T') master=$final ===" >> "$LOG"
bash "$ROOT/scripts/notify.sh" "✅ farm to-2k loop done" "farm master: $final records (target $TARGET)"
