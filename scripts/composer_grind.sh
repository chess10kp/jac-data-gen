#!/usr/bin/env bash
# Outer grinder: run composer chunks back-to-back from START offset to end of
# dataset. Each chunk is prep->composer->guard->append (composer_chunk.sh).
# Resume-safe: re-running skips chunks whose dataset already exists.
# Usage: composer_grind.sh <start_offset> [chunk_size]
set -uo pipefail
cd "$(dirname "$0")/.."
START="${1:-9000}"; SIZE="${2:-2000}"
LOG="data/composer_grind.log"
echo "=== grind start $(date '+%F %T') from offset $START, size $SIZE ===" >> "$LOG"

off="$START"
while true; do
  tag="chunk_${off}"
  if [ -f "data/chunks/${tag}/dataset.jsonl" ]; then
    echo "[grind] $tag already done — skip" | tee -a "$LOG"
    off=$((off + SIZE)); continue
  fi
  echo "[grind] === $tag (offset $off) $(date '+%T') ===" | tee -a "$LOG"
  bash scripts/composer_chunk.sh "$off" "$SIZE" >> "$LOG" 2>&1
  rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "[grind] reached end of dataset at offset $off — DONE" | tee -a "$LOG"
    break
  elif [ "$rc" -ne 0 ]; then
    echo "[grind] $tag failed (rc=$rc) — retrying once" | tee -a "$LOG"
    bash scripts/composer_chunk.sh "$off" "$SIZE" >> "$LOG" 2>&1 || {
      echo "[grind] $tag failed twice — skipping to next" | tee -a "$LOG"; }
  fi
  # free per-chunk work/batches to bound disk (keep dataset + candidates)
  rm -rf "data/chunks/${tag}/work" "data/chunks/${tag}/batches" 2>/dev/null || true
  master_n=$(wc -l < data/composer_dataset.jsonl 2>/dev/null || echo 0)
  echo "[grind] master total: ${master_n} records" | tee -a "$LOG"
  off=$((off + SIZE))
done
echo "=== grind end $(date '+%F %T') ===" >> "$LOG"
