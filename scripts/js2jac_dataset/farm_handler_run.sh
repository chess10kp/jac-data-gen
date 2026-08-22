#!/usr/bin/env bash
# Handler-mode FARM pipeline: bundle whole apps from farm_models repos -> handler
# prep (real FastAPI route/db/auth code as translation context) -> composer ->
# guard -> append to a SEPARATE master (farm_handler_dataset.jsonl) so the
# schema-only corpus stays clean. Loops until the bundles file is consumed.
# Usage: farm_handler_run.sh [chunk_size]      (env: WORKERS=3 passes to composer)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"
PY="${PY:-python3}"
MODELS="scripts/js2jac_dataset/farm_models.jsonl"
APPS="scripts/js2jac_dataset/farm_apps.jsonl"
DIR="data/farm_handler"
LOG="data/farm_handler.log"
mkdir -p "$DIR"
echo "=== farm handler run start $(date '+%F %T') ===" | tee -a "$LOG"

# singleton across handler runs
exec 9>/tmp/farm_handler.lock
if ! flock -n 9; then
  echo "[handler] another handler run holds the lock — refusing" >&2
  exit 5
fi

# stage 0: bundle every unique repo not already bundled (clone-on-demand, slow)
n=$(wc -l < "$APPS" 2>/dev/null || echo 0)
echo "[handler] bundles: $n — bundling missing repos from $MODELS" | tee -a "$LOG"
"$PY" scripts/js2jac_dataset/farm_app_bundle.py \
  --repos-from "$MODELS" --out "$APPS" 2>&1 | tee -a "$LOG"
n=$(wc -l < "$APPS" 2>/dev/null || echo 0)
echo "[handler] bundles now: $n" | tee -a "$LOG"

# stage 1+: chunk grind over bundles in handler mode (PREP=handler)
SIZE="${1:-500}"
off=0
while :; do
  tag="hchunk_${off}"
  W="data/farm_handler/${tag}"
  if [ -f "$W/.done" ]; then
    off=$((off+SIZE)); continue
  fi
  mkdir -p "$W"
  echo "[handler] === $tag (offset $off) $(date '+%T') ===" | tee -a "$LOG"
  PREP=handler WORKERS="${WORKERS:-3}" bash scripts/js2jac_dataset/farm_chunk.sh \
    "$off" "$SIZE" "$APPS" data/farm_handler_dataset.jsonl >> "$LOG" 2>&1
  rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "[handler] end of bundles at offset $off — DONE" | tee -a "$LOG"
    break
  elif [ "$rc" -ne 0 ]; then
    echo "[handler] $tag failed rc=$rc — retry once" | tee -a "$LOG"
    bash scripts/js2jac_dataset/farm_chunk.sh "$off" "$SIZE" scripts/js2jac_dataset/farm_apps.jsonl data/farm_handler_dataset.jsonl >> "$LOG" 2>&1 || \
      echo "[handler] $tag failed twice — skipping" | tee -a "$LOG"
  fi
  touch "$W/.done"
  echo "[handler] master total: $(wc -l < data/farm_handler_dataset.jsonl 2>/dev/null || echo 0)" | tee -a "$LOG"
  off=$((off+SIZE))
done
echo "=== farm handler run end $(date '+%F %T') master=$(wc -l < data/farm_handler_dataset.jsonl 2>/dev/null || echo 0) ===" | tee -a "$LOG"
bash scripts/notify.sh "✅ farm handler run done" "handler master: $(wc -l < data/farm_handler_dataset.jsonl 2>/dev/null || echo 0) records"
