#!/usr/bin/env bash
# Resume the orphaned floorfix rescue (guard died at 143/5767 on Aug 19).
# Generate is already complete (5777/5777 non-null candidates) — zero model
# calls needed. Guard skips done ids in results.jsonl; merge then applies
# flips to composer master + regenerates the idiomatic export.
# TMPDIR for guard MUST be /tmp (embedded PG socket; memory id 751).
set -u
cd "$(dirname "$0")/.."
PY=.venv/bin/python
DIR=archive/2026-09/scratch/floorfix
LOG=$DIR/resume_guard.log

exec 8>/tmp/floorfix_resume.lock
if ! flock -n 8; then
  echo "[resume] another floorfix resume holds the lock — refusing" >&2
  exit 5
fi

echo "=== resume guard start $(date '+%F %T') ===" | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase guard --workers 6 --shared-tmp /tmp 2>&1 | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase merge 2>&1 | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase status 2>&1 | tee -a "$LOG"
echo "=== resume guard end $(date '+%F %T') ===" | tee -a "$LOG"
bash scripts/notify.sh "✅ floorfix resume (guard+merge) done" "see $LOG"
