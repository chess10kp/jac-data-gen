#!/usr/bin/env bash
# Full floor->idiomatic fanout: prep -> generate (+retry) -> guard (warm PG)
# -> merge -> status. Resume-safe end to end; see scripts/floorfix.py --help.
set -u
cd "$(dirname "$0")/.."
PY=.venv/bin/python
DIR=data/floorfix
LOG=$DIR/run.log
PGTMP=/tmp/floorfix_pg0
mkdir -p "$DIR" "$PGTMP"
echo "=== floorfix full run start $(date '+%F %T') ===" | tee -a "$LOG"

# environment heal guard: leaked PG shm blocks every boot ("shared memory block
# still in use"). Detect and clear BEFORE burning hours into silent rejects.
pg_ok() {
  ipcs -m 2>/dev/null | awk '$2!="" && $6==0 && $4=="jac" {exit 1}'; return $? 2>/dev/null || true
}

$PY -u scripts/floorfix.py --phase prep --workers 8 --shared-tmp "$PGTMP" 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase generate --workers 6 --call-timeout 240 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase generate --retry-empty --workers 4 --call-timeout 240 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase guard --workers 6 --shared-tmp "$PGTMP" 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase merge 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase status 2>&1 | tee -a "$LOG"
echo "=== floorfix full run end $(date '+%F %T') ===" | tee -a "$LOG"
