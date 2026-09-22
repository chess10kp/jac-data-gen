#!/usr/bin/env bash
# Watch the two current runs and desktop-ping at every terminal state:
#   A) reguard_paid.sh  — self-notifies on done/FAIL; this catches silent death
#   B) floorfix_rescue.sh — pings summary on '=== rescue end', critical on silent death
set -u
cd "$(dirname "$0")/.."
LOG=archive/2026-09/scratch/floorfix/notify_watch.log
echo "=== run-watcher start $(date '+%F %T') ===" >> "$LOG"

# ---- A: paid re-guard ---------------------------------------------------- #
while pgrep -f 'reguard_paid\.sh' >/dev/null 2>&1; do sleep 60; done
if ! grep -q '=== reguard-paid end' archive/2026-09/scratch/floorfix/reguard_paid.log 2>/dev/null; then
  bash scripts/notify.sh "🚨 reguard-paid DIED" "reguard_paid.sh gone without end marker — no self-notify fired. Check archive/2026-09/scratch/floorfix/reguard_paid.log" critical
  echo "[A-DEAD] $(date '+%T')" >> "$LOG"
else
  echo "[A-ok] $(date '+%T') reguard ended cleanly (self-notified)" >> "$LOG"
fi

# ---- B: free-model rescue ------------------------------------------------ #
while pgrep -f 'floorfix_rescue\.sh' >/dev/null 2>&1; do sleep 60; done
if tail -5 archive/2026-09/scratch/floorfix/rescue.log 2>/dev/null | grep -q '=== rescue end'; then
  ST=$(tail -3 archive/2026-09/scratch/floorfix/rescue.log | tr '\n' ' ' | cut -c1-180)
  bash scripts/notify.sh "✅ Free-model floor rescue done" "$ST"
  echo "[B] $(date '+%T') rescue done" >> "$LOG"
else
  bash scripts/notify.sh "🚨 floorfix rescue DIED" "rescue.sh exited without a completion marker. Check archive/2026-09/scratch/floorfix/rescue.log" critical
  echo "[B-FAIL] $(date '+%T')" >> "$LOG"
fi
echo "=== run-watcher end $(date '+%F %T') ===" >> "$LOG"
