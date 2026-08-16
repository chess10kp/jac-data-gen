#!/usr/bin/env bash
# One end-to-end composer chunk: prep -> composer -> guard -> append to master.
# Usage: composer_chunk.sh <offset> <limit>
# Idempotent per chunk (resume-safe on candidates); temp isolated + purged.
set -euo pipefail
cd "$(dirname "$0")/.."
OFFSET="${1:?offset}"; LIMIT="${2:-2000}"
TAG="chunk_${OFFSET}"
WORK="data/chunks/${TAG}/work"
BATCH="data/chunks/${TAG}/batches"
CAND="data/chunks/${TAG}/candidates.jsonl"
DS="data/chunks/${TAG}/dataset.jsonl"
MASTER="data/composer_dataset.jsonl"
PY=.venv/bin/python
TMP="/tmp/jactmp_${TAG}"

mkdir -p "$WORK" "$BATCH" "$TMP"

echo "[$TAG] 1/4 prep (offset=$OFFSET limit=$LIMIT)"
TMPDIR="$TMP" $PY scripts/agent_idiomize_prep.py \
  --offset "$OFFSET" --limit "$LIMIT" --workers 8 --work-dir "$WORK" \
  2>&1 | grep -v "cached\|Found the latest" || true
rm -rf "$TMP"/* 2>/dev/null || true
N=$(ls "$WORK"/*.json 2>/dev/null | wc -l)
echo "[$TAG] prepped $N floor-pass records"
[ "$N" -eq 0 ] && { echo "[$TAG] no records (end of dataset?) — stopping"; exit 3; }

echo "[$TAG] 2/4 pack batches"
$PY - "$WORK" "$BATCH" <<'PYEOF'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json"))); B = 10
for i in range(0, len(files), B):
    recs = [{k: json.load(open(f))[k] for k in ("id","entrypoint","floor_fn","python")}
            for f in files[i:i+B]]
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs))
print(f"  {len(files)} -> {(len(files)+B-1)//B} batches")
PYEOF

echo "[$TAG] 3/4 composer idiomize (MCP off, batched)"
# Only ONE composer driver may run at a time (they share MCP disable/enable).
# Serialize via an flock; wait up to 6h for the lock.
exec 9>/tmp/composer.lock
flock -w 21600 9 || { echo "[$TAG] could not acquire composer lock"; exit 4; }
$PY scripts/cursor_composer_batch.py \
  --batch-dir "$BATCH" --out "$CAND" --model composer-2.5 --workers 6 --timeout 360
flock -u 9

echo "[$TAG] 4/4 guard + append to $MASTER"
mkdir -p "$TMP"
TMPDIR="$TMP" $PY scripts/agent_idiomize_guard.py \
  --work-dir "$WORK" --candidates "$CAND" --out "$DS" --workers 12 2>&1 | tail -2
rm -rf "$TMP"

# append with chunk tag; guard-writes dataset each run, so append fresh
$PY - "$DS" "$MASTER" "$TAG" <<'PYEOF'
import json, sys, os
ds, master, tag = sys.argv[1], sys.argv[2], sys.argv[3]
rows = [json.loads(l) for l in open(ds)]
# de-dup against master by id (resume-safe)
seen = set()
if os.path.exists(master):
    for l in open(master):
        seen.add(json.loads(l)["id"])
with open(master, "a") as fh:
    added = 0
    for r in rows:
        if r["id"] not in seen:
            r["chunk"] = tag; fh.write(json.dumps(r) + "\n"); added += 1
    print(f"  appended {added} new records to {master} (total now {len(seen)+added})")
PYEOF
echo "[$TAG] DONE"
