#!/usr/bin/env bash
# Run the REAL composer (cursor_composer_batch --model composer-2.5) on the
# already-prepped floor work records (data/floorfix/work), then guard + merge
# flips into the master. Mirrors composer_chunk.sh steps 2-4, but scoped to the
# floor ids instead of a source offset/limit. Resume-safe on candidates.
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="floorfix"
WORK="data/floorfix/work"
BATCH="data/floorfix/batches"
CAND="data/floorfix/composer_candidates.jsonl"
DS="data/floorfix/composer_dataset.jsonl"
MASTER="data/composer_dataset.jsonl"
PY=.venv/bin/python
TMP="/tmp/jactmp_${TAG}"
LOG="data/floorfix/composer_run.log"

mkdir -p "$BATCH" "$TMP"
echo "=== floorfix composer start $(date '+%F %T') ===" | tee -a "$LOG"

N=$(ls "$WORK"/*.json 2>/dev/null | wc -l)
echo "[$TAG] work records: $N" | tee -a "$LOG"
[ "$N" -eq 0 ] && { echo "[$TAG] no work records — stopping"; exit 3; }

echo "[$TAG] 1/3 pack batches" | tee -a "$LOG"
$PY - "$WORK" "$BATCH" <<'PYEOF' | tee -a "$LOG"
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json"))); B = 10
for i in range(0, len(files), B):
    recs = [{k: json.load(open(f))[k] for k in ("id","entrypoint","floor_fn","python")}
            for f in files[i:i+B]]
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs))
print(f"  {len(files)} -> {(len(files)+B-1)//B} batches")
PYEOF

echo "[$TAG] 2/3 composer idiomize (MCP off, batched; waits on shared lock)" | tee -a "$LOG"
exec 9>/tmp/composer.lock
flock -w 21600 9 || { echo "[$TAG] could not acquire composer lock"; exit 4; }
$PY scripts/cursor_composer_batch.py \
  --batch-dir "$BATCH" --out "$CAND" --model composer-2.5 --workers 6 --timeout 360 \
  2>&1 | tee -a "$LOG"
flock -u 9

echo "[$TAG] 3/3 guard + merge flips into $MASTER" | tee -a "$LOG"
mkdir -p "$TMP"
TMPDIR="$TMP" $PY scripts/agent_idiomize_guard.py \
  --work-dir "$WORK" --candidates "$CAND" --out "$DS" --workers 12 2>&1 | tail -3 | tee -a "$LOG"
rm -rf "$TMP"

# Merge: flip master rows whose composer candidate now guards to idiomatic.
$PY - "$DS" "$MASTER" <<'PYEOF' 2>&1 | tee -a "$LOG"
import json, sys, os, time
ds, master = sys.argv[1], sys.argv[2]
new = {}
for l in open(ds):
    r = json.loads(l)
    if r.get("source") == "idiomatic":
        new[r["id"]] = r
rows = [json.loads(l) for l in open(master)]
flipped = 0
for r in rows:
    if r["id"] in new and r.get("source") != "idiomatic":
        r["jac"] = new[r["id"]]["jac"]; r["source"] = "idiomatic"; flipped += 1
bak = f"{master}.bak.{int(os.path.getmtime(master))}"
os.replace(master, bak)
with open(master, "w") as fh:
    for r in rows:
        fh.write(json.dumps(r) + "\n")
idi = sum(1 for r in rows if r.get("source") == "idiomatic")
print(f"  flipped {flipped} floor->idiomatic; master now {idi} idiomatic / {len(rows)} total (bak: {bak})")
PYEOF
echo "=== floorfix composer end $(date '+%F %T') ===" | tee -a "$LOG"
