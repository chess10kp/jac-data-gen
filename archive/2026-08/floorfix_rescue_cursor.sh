#!/usr/bin/env bash
# Cursor-agent floorfix rescue (replaces the dead free-zen path):
#   cursor idiomize generate (retry-empty) -> guard (behavioral) -> merge -> status
# TMPDIR for guard MUST be /tmp (embedded PG socket; memory id 751).
set -u
cd "$(dirname "$0")/.."
PY=.venv/bin/python
DIR=data/floorfix
LOG=$DIR/rescue_cursor.log
mkdir -p "$DIR"

exec 8>/tmp/floorfix_rescue_cursor.lock
if ! flock -n 8; then
  echo "[rescue-cursor] another cursor rescue holds the lock — refusing" >&2
  exit 5
fi

echo "=== cursor rescue start $(date '+%F %T') ===" | tee -a "$LOG"
"$PY" -u scripts/floorfix_cursor_batch.py --retry-empty --workers 3 2>&1 | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase guard --workers 6 --shared-tmp /tmp 2>&1 | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase merge 2>&1 | tee -a "$LOG"
"$PY" -u scripts/floorfix.py --phase status 2>&1 | tee -a "$LOG"
echo "=== cursor rescue end $(date '+%F %T') ===" | tee -a "$LOG"
bash scripts/notify.sh "✅ floorfix cursor rescue done" "see $LOG"
