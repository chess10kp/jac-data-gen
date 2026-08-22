#!/usr/bin/env bash
# Outer js2jac grinder: run js2jac_chunk.sh back-to-back from START offset
# through source/candidates.jsonl. Resume-safe: chunks with dataset.jsonl are
# skipped. rc=3 from a chunk means candidates exhausted -> stop.
# Usage: js2jac_grind.sh <start_offset> [repo_limit] [--faithful]
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

# singleton: refuse to run two grinders over the same source (double-spend guard)
exec 8>/tmp/js2jac_grind.lock
if ! flock -n 8; then
  echo "[grind] another js2jac grind holds /tmp/js2jac_grind.lock — refusing to start" >&2
  exit 5
fi

START="${1:-0}"; SIZE="${2:-20}"; FAITHFUL="${3:-}"
LOG="runs/js2jac_grind.log"
mkdir -p runs
echo "=== js2jac grind start $(date '+%F %T') from offset $START, size $SIZE ===" >> "$LOG"

off="$START"
while true; do
  tag="js2jac_${off}"
  if [ -f "runs/${tag}/dataset.jsonl" ]; then
    echo "[grind] $tag already done — skip" | tee -a "$LOG"
    off=$((off + SIZE)); continue
  fi
  echo "[grind] === $tag (offset $off) $(date '+%T') ===" | tee -a "$LOG"
  bash js2jac_chunk.sh "$off" "$SIZE" $FAITHFUL >> "$LOG" 2>&1
  rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "[grind] reached end of candidates at offset $off — DONE" | tee -a "$LOG"
    break
  elif [ "$rc" -ne 0 ]; then
    echo "[grind] $tag failed (rc=$rc) — retrying once" | tee -a "$LOG"
    bash js2jac_chunk.sh "$off" "$SIZE" $FAITHFUL >> "$LOG" 2>&1 || {
      echo "[grind] $tag failed twice — skipping to next" | tee -a "$LOG"; }
  fi
  rm -rf "runs/${tag}/work" "runs/${tag}/batches" 2>/dev/null || true
  master_n=$(wc -l < js2jac_dataset.jsonl 2>/dev/null || echo 0)
  echo "[grind] master total: ${master_n} records" | tee -a "$LOG"
  off=$((off + SIZE))
done
echo "=== js2jac grind end $(date '+%F %T') ===" >> "$LOG"
bash "$(dirname "$0")/notify.sh" "✅ js2jac grind done" "master total: $(wc -l < "$(dirname "$0")/js2jac_dataset.jsonl" 2>/dev/null || echo '?') records — runs/js2jac_grind.log"
