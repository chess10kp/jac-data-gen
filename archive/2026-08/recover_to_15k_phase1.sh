#!/usr/bin/env bash
# Phase 1 toward 15k: guard-drain the 3 chunks that have composer candidates
# already produced but never guarded into the master (chunk_9000/15000/17000).
# Pure recovery — no prep, no model calls. Sequential to bound RAM; each guard
# run uses TMPDIR under /tmp and sub-batches of 100 with gc between.
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
MASTER=data/composer_dataset.jsonl
LOG=scripts/js2jac_dataset/source/runs/recover_phase1.log
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
log() { echo "[$(date '+%F %T')] $*"; }

log "=== phase1 start; master=$(wc -l < "$MASTER") free=$(df -BG / | awk 'NR==2{print $4}') ==="
for OFF in 9000 15000 17000; do
  TAG=chunk_${OFF}; RTAG=rec_${OFF}
  WORK=data/chunks/${TAG}/work; CAND=data/chunks/${TAG}/candidates.jsonl
  TMP=/tmp/jactmp_${TAG}_g
  log "--- $TAG master_before=$(wc -l < "$MASTER") ---"
  [ -f "$CAND" ] || { log "$TAG no candidates — skip"; continue; }
  mkdir -p "$TMP"
  TMPDIR="$TMP" $PY scripts/composer_guard_recover.py \
    --work-dir "$WORK" --candidates "$CAND" --tag "$RTAG" \
    --sub-batch 100 --workers 4 || log "$TAG guard-recover NONZERO rc"
  rm -rf "$TMP"
  log "--- $TAG done master_after=$(wc -l < "$MASTER") ---"
  gc_status=$(df -BG / | awk 'NR==2{print $4}')
  log "--- free=$gc_status ---"
done
log "=== phase1 DONE; master=$(wc -l < "$MASTER") ==="
