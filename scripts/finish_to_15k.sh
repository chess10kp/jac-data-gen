#!/usr/bin/env bash
# Finish master to 15,000: bank repaired passers -> guard remaining candidates
# -> (if short) collect/compose/guard new virgin repair bands. Resumable.
set -u
cd "$(dirname "$0")/.."
PY=.venv/bin/python
SCALED=data/chunks/repair_scaled
PROTO=data/chunks/repair_proto
LOG=$SCALED/finish.log
TARGET=15000
NEXT_OFFSET_FILE=$SCALED/next_offset
echo "=== finish_to_15k start $(date '+%F %T') ===" | tee -a "$LOG"

bank () {
  $PY - <<'EOF'
import json
master = 'data/composer_dataset.jsonl'
seen = set()
rows = []
for ln in open(master):
    try: rows.append(json.loads(ln)); seen.add(json.loads(ln)['id'])
    except Exception: pass
added = 0
for src in ['data/chunks/repair_scaled/repaired.jsonl', 'data/chunks/repair_proto/repaired.jsonl']:
    try:
        for ln in open(src):
            if not ln.strip(): continue
            try: r = json.loads(ln)
            except Exception: continue
            if r.get('outcome') == 'repaired' and r['id'] not in seen:
                seen.add(r['id'])
                row = {'id': r['id'], 'jac': r['jac'], 'entrypoint': r['entrypoint'],
                       'source': 'floor', 'chunk': 'rec_repair'}
                rows.append(row); open(master, 'a').write(json.dumps(row) + '\n'); added += 1
    except FileNotFoundError: pass
print(f"banked +{added} -> master {len(rows)}")
EOF
}

unguarded () {
  $PY - <<'EOF'
import json, pathlib
out = pathlib.Path('data/chunks/repair_scaled')
done = set()
try:
    for ln in (out/'repaired.jsonl').read_text().splitlines():
        if ln.strip():
            try: done.add(json.loads(ln)['id'])
            except Exception: pass
except FileNotFoundError: pass
cands = set()
try:
    for ln in (out/'candidates.jsonl').read_text().splitlines():
        if ln.strip():
            try: cands.add(json.loads(ln)['id'])
            except Exception: pass
except FileNotFoundError: pass
print(len(cands - done))
EOF
}

master_n () { wc -l < data/composer_dataset.jsonl; }

# circuit breaker: N consecutive guard failures with NO progress -> abort
# (the NUL-corruption crash-loop class: bank->guard-crash every ~1s forever)
FAILS=0; LAST_M=-1; LAST_U=-1
GUARD_FAIL_LIMIT=${GUARD_FAIL_LIMIT:-3}

while true; do
  echo "--- $(date '+%T') bank ---" | tee -a "$LOG"
  bank | tee -a "$LOG"
  N=$(master_n)
  echo "[finish] master = $N / $TARGET" | tee -a "$LOG"
  if [ "$N" -ge "$TARGET" ]; then
    echo "TARGET REACHED" | tee -a "$LOG"
    break
  fi

  U=$(unguarded)
  if [ "$U" -gt 0 ]; then
    # progress check: did the last guard pass change anything?
    if [ "$U" -eq "$LAST_U" ] && [ "$N" -eq "$LAST_M" ]; then
      FAILS=$((FAILS + 1))
      echo "[finish] no-progress failure $FAILS/$GUARD_FAIL_LIMIT (U=$U master=$N)" | tee -a "$LOG"
      if [ "$FAILS" -ge "$GUARD_FAIL_LIMIT" ]; then
        echo "[finish] CIRCUIT BREAKER: $FAILS consecutive no-progress guard failures — aborting (input likely corrupt; fix and rerun)" | tee -a "$LOG"
        break
      fi
    else
      FAILS=0
    fi
    LAST_U=$U; LAST_M=$N
    echo "[finish] guarding $U unguarded candidates $(date '+%T')" | tee -a "$LOG"
    $PY scripts/repair_pass.py guard --out-dir "$SCALED" --workers 6 --test-timeout 300 \
      >> "$LOG" 2>&1 || echo "[finish] guard rc=$? (continuing)" | tee -a "$LOG"
    continue
  fi
  FAILS=0; LAST_U=-1; LAST_M=-1

  OFF=$(cat "$NEXT_OFFSET_FILE" 2>/dev/null || echo 1330)
  echo "[finish] no candidates left — new band offset=$OFF $(date '+%T')" | tee -a "$LOG"
  $PY scripts/repair_pass.py collect --out-dir "$SCALED" --offset "$OFF" --limit 400 --workers 6 \
    >> "$LOG" 2>&1 || { echo "[finish] collect rc=$? — aborting" | tee -a "$LOG"; break; }
  # stop if collect found nothing (end of dataset)
  W=$(ls "$SCALED"/work/*.json 2>/dev/null | wc -l)
  C=$(unguarded); [ "$W" -lt "$C" ] && C=$W
  if [ "$W" -eq 0 ]; then echo "[finish] end of dataset — aborting" | tee -a "$LOG"; break; fi
  echo "$((OFF + 400))" > "$NEXT_OFFSET_FILE"
  $PY scripts/repair_pass.py compose --out-dir "$SCALED" --workers 4 --model composer-2.5 --timeout 360 \
    >> "$LOG" 2>&1 || echo "[finish] compose rc=$? (continuing)" | tee -a "$LOG"
done

echo "=== finish_to_15k end $(date '+%F %T') master=$(master_n) ===" | tee -a "$LOG"
bash "$(dirname "$0")/notify.sh" "finish_to_15k done" "master=$(master_n) / $TARGET — $LOG"
