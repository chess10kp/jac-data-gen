#!/usr/bin/env bash
# Watch the floorfix pipeline and ping the desktop at each terminal state:
#   A) composer guard+merge done   -> summary ping (idiomatic/total master)
#   B) composer exited WITHOUT merge output -> critical failure ping
#   C) free-model rescue done      -> summary ping (status tail)
# Also pings critical if rescue dies unexpectedly (log goes stale).
set -u
cd "$(dirname "$0")/.."
LOG=archive/2026-09/scratch/floorfix/notify_watch.log
echo "=== notify watcher start $(date '+%F %T') ===" >> "$LOG"

master_idi () {  # idiomatic count in master composer_dataset.jsonl
  python3 -c "
import json,collections
c=collections.Counter()
for l in open('data/composer_dataset.jsonl'):
    try: c[json.loads(l).get('source','?')]+=1
    except Exception: pass
print(f\"{c.get('idiomatic',0)}/{sum(c.values())}\")" 2>/dev/null || echo "?"
}

# ---- Stage A: composer guard+merge -------------------------------------- #
while pgrep -f 'floorfix_composer\.sh' >/dev/null 2>&1; do sleep 60; done
if [ -f archive/2026-09/scratch/floorfix/composer_dataset.jsonl ]; then
  N=$(master_idi)
  bash scripts/notify.sh "✅ Composer guard+merge done" "floorfix composer finished: master now $N idiomatic. Free-model rescue starting."
  echo "[A] $(date '+%T') composer done: $N idiomatic" >> "$LOG"
else
  bash scripts/notify.sh "🚨 floorfix composer FAILED" "floorfix_composer.sh exited but composer_dataset.jsonl is missing — guard died before output. Check archive/2026-09/scratch/floorfix/composer_run.log" critical
  echo "[A-FAIL] $(date '+%T')" >> "$LOG"
fi

# ---- Stage B: free-model rescue ----------------------------------------- #
while pgrep -f 'floorfix_rescue\.sh' >/dev/null 2>&1; do sleep 60; done
if tail -5 archive/2026-09/scratch/floorfix/rescue.log 2>/dev/null | grep -q '=== rescue end'; then
  ST=$(tail -3 archive/2026-09/scratch/floorfix/rescue.log | tr '\n' ' ' | cut -c1-180)
  bash scripts/notify.sh "✅ Free-model floor rescue done" "$ST"
  echo "[B] $(date '+%T') rescue done" >> "$LOG"
else
  bash scripts/notify.sh "🚨 floorfix rescue DIED" "rescue.sh exited without a completion marker. Check archive/2026-09/scratch/floorfix/rescue.log" critical
  echo "[B-FAIL] $(date '+%T')" >> "$LOG"
fi
echo "=== notify watcher end $(date '+%F %T') ===" >> "$LOG"
