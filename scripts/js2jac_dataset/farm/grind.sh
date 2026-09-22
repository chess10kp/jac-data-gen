#!/usr/bin/env bash
# Outer FARM grinder: run chunks back-to-back from START offset to end of the
# models file. Each chunk is prep->composer->guard->append (farm_chunk.sh).
# Resume-safe: a chunk with a .done marker is skipped. rc=3 from a chunk means
# the models file is exhausted -> stop.
# Usage: farm/grind.sh <start_offset> [size] [models.jsonl]
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
cd "$ROOT"

# singleton: refuse to run two farm grinders over the same models file
exec 8>/tmp/farm_grind.lock
if ! flock -n 8; then
  echo "[farm] another farm grind holds /tmp/farm_grind.lock — refusing to start" >&2
  exit 5
fi

START="${1:-0}"; SIZE="${2:-500}"
MODELS="${3:-scripts/js2jac_dataset/farm_models.jsonl}"
LOG="archive/2026-09/data_logs/farm_grind.log"
echo "=== farm grind start $(date '+%F %T') from $START size $SIZE ($MODELS) ===" >> "$LOG"

off="$START"
while true; do
  tag="chunk_${off}"
  if [ -f "archive/2026-09/scratch/farm_chunks/${tag}/.done" ]; then
    echo "[grind] $tag already done — skip" | tee -a "$LOG"
    off=$((off + SIZE)); continue
  fi
  echo "[grind] === $tag (offset $off) $(date '+%T') ===" | tee -a "$LOG"
  bash "$HERE/chunk.sh" "$off" "$SIZE" "$MODELS" >> "$LOG" 2>&1
  rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "[grind] end of models at offset $off — DONE" | tee -a "$LOG"
    break
  elif [ "$rc" -ne 0 ]; then
    echo "[grind] $tag failed (rc=$rc) — retrying once" | tee -a "$LOG"
    bash "$HERE/chunk.sh" "$off" "$SIZE" "$MODELS" >> "$LOG" 2>&1 || \
      echo "[grind] $tag failed twice — skipping" | tee -a "$LOG"
  fi
  touch "archive/2026-09/scratch/farm_chunks/${tag}/.done"
  # free per-chunk work/batches; keep candidates + master
  rm -rf "archive/2026-09/scratch/farm_chunks/${tag}/batches" 2>/dev/null || true
  echo "[grind] master total: $(wc -l < data/farm_dataset.jsonl 2>/dev/null || echo 0)" | tee -a "$LOG"
  off=$((off + SIZE))
done
echo "=== farm grind end $(date '+%F %T') ===" >> "$LOG"
bash "$ROOT/scripts/ops/notify.sh" "✅ farm grind done" "farm master: $(wc -l < data/farm_dataset.jsonl 2>/dev/null || echo 0) records"
