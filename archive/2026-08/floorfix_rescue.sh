#!/usr/bin/env bash
# Free-model floor rescue: waits for the floorfix composer guard+merge to land,
# moves composer-idiomatic work files aside (their floors flipped — no rescue
# needed), then runs floorfix generate (FREE models) -> guard -> merge on the
# remaining floors. Zero paid tokens. Singleton-locked; fully logged (no tail).
set -u
cd "$(dirname "$0")/.."
PY=.venv/bin/python
DIR=data/floorfix
LOG=$DIR/rescue.log
PGTMP=/tmp   # MUST be /tmp: the live embedded PG socket lives at $TMPDIR/jacpg-*; any other dir hides it -> 0% flips (memory id 751)
mkdir -p "$DIR"

# singleton
exec 8>/tmp/floorfix_rescue.lock
if ! flock -n 8; then
  echo "[rescue] another rescue holds the lock — refusing to start" >&2
  exit 5
fi

echo "=== rescue watcher start $(date '+%F %T') ===" | tee -a "$LOG"

# 1. wait for floorfix_composer.sh (guard+merge) to finish
while pgrep -f 'floorfix_composer.sh' >/dev/null 2>&1; do
  echo "[rescue] $(date '+%T') waiting for composer guard+merge to finish..." | tee -a "$LOG"
  sleep 120
done

if [ ! -f "$DIR/composer_dataset.jsonl" ]; then
  echo "[rescue] FATAL: composer_dataset.jsonl missing after composer exited — aborting" | tee -a "$LOG"
  exit 1
fi

# 2. move composer-idiomatic work files aside so generate only rescues still-floor ids
$PY - <<'PYEOF' | tee -a "$LOG"
import json, shutil
from pathlib import Path
idi = set()
for l in open('data/floorfix/composer_dataset.jsonl'):
    r = json.loads(l)
    if r.get('source') == 'idiomatic':
        idi.add(str(r['id']))
work = Path('data/floorfix/work'); flipped = Path('data/floorfix/work_flipped')
flipped.mkdir(exist_ok=True)
moved = 0
for f in list(work.glob('*.json')):
    if f.stem in idi:
        shutil.move(str(f), flipped / f.name); moved += 1
print(f"[rescue] moved {moved} composer-idiomatic work files aside; "
      f"{len(list(work.glob('*.json')))} floors remain to rescue")
PYEOF

# 3. free-model generate -> retry empties -> guard (visible, no tail-swallow) -> merge
$PY -u scripts/floorfix.py --phase generate --workers 6 --call-timeout 240 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase generate --retry-empty --workers 4 --call-timeout 240 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase guard --workers 6 --shared-tmp "$PGTMP" 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase merge 2>&1 | tee -a "$LOG"
$PY -u scripts/floorfix.py --phase status 2>&1 | tee -a "$LOG"
echo "=== rescue end $(date '+%F %T') ===" | tee -a "$LOG"
