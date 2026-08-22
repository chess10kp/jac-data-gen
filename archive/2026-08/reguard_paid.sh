#!/usr/bin/env bash
# Re-guard the PAID composer-2.5 floorfix candidates under the fixed PG env,
# then merge flips into the master. Detached runner with notification.
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
LOG=data/floorfix/reguard_paid.log

echo "=== reguard-paid start $(date '+%F %T') ===" | tee -a "$LOG"
$PY -u scripts/reguard_paid.py --phase guard --workers 10 2>&1 | tee -a "$LOG"
rc=$?
echo "guard rc=$rc" | tee -a "$LOG"

if [ "$rc" -eq 0 ]; then
  $PY -u scripts/reguard_paid.py --phase merge 2>&1 | tee -a "$LOG"
  bash scripts/notify.sh "reguard-paid done" "$(grep -E '\[merge\] master' "$LOG" | tail -1)"
else
  bash scripts/notify.sh "reguard-paid FAILED" "rc=$rc — $LOG"
fi
echo "=== reguard-paid end $(date '+%F %T') ===" | tee -a "$LOG"
