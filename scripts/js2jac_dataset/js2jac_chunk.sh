#!/usr/bin/env bash
# One end-to-end js2jac cleanup chunk: prep -> pack -> composer -> guard -> append.
# Analog of scripts/composer_chunk.sh (py2jac). Difference: the guard gate is
# `jac check` passing (js2jac has no unit tests), which is weaker than py2jac's
# test suite — so REJECT in strip_policy.json carries more weight here.
#
# Usage: js2jac_chunk.sh <offset> <limit> [--faithful]
set -euo pipefail
cd "$(dirname "$0")"                      # scripts/js2jac_dataset
OFFSET="${1:?offset}"; LIMIT="${2:-40}"; FAITHFUL="${3:-}"
TAG="js2jac_${OFFSET}"
WORK="runs/${TAG}/work"
BATCH="runs/${TAG}/batches"
CAND="runs/${TAG}/candidates.jsonl"
DS="runs/${TAG}/dataset.jsonl"
MASTER="js2jac_dataset.jsonl"
CANDS="source/candidates.jsonl"
JAC_REPO="/home/jac/repos/jac_llm_data/jaseci/jac"
PY="/home/jac/repos/jac_llm_data/.venv/bin/python"

mkdir -p "$WORK" "$BATCH"

echo "[$TAG] 1/4 prep (offset=$OFFSET limit=$LIMIT)"
set +e
$PY js2jac_prep.py --candidates "$CANDS" --offset "$OFFSET" --limit "$LIMIT" \
  --work-dir "$WORK" --profile react
rc=$?
set -e
[ "$rc" -eq 3 ] && { echo "[$TAG] no records (end of slice) — stopping"; exit 3; }
N=$(ls "$WORK"/*.json 2>/dev/null | grep -v '/_emitted' | wc -l)
echo "[$TAG] prepped $N per-file records"

echo "[$TAG] 2/4 pack batches"
$PY - "$WORK" "$BATCH" <<'PYEOF'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = [f for f in sorted(glob.glob(os.path.join(work, "*.json")))
         if os.path.basename(f) != "report.json"]
B = 6  # smaller than py2jac (10): source+floor payloads are larger
recs = [json.load(open(f)) for f in files]
for i in range(0, len(recs), B):
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs[i:i+B]))
print(f"  {len(recs)} -> {(len(recs)+B-1)//B} batches")
PYEOF

echo "[$TAG] 3/4 composer cleanup (MCP off, batched)"
exec 9>/tmp/composer.lock          # same lock as py2jac: one composer driver at a time
flock -w 21600 9 || { echo "[$TAG] could not acquire composer lock"; exit 4; }
$PY js2jac_composer_batch.py --batch-dir "$BATCH" --out "$CAND" \
  --model composer-2.5 --workers 6 --timeout 360 $FAITHFUL
flock -u 9

echo "[$TAG] 4/4 guard (jac check) + append to $MASTER"
$PY - "$WORK" "$CAND" "$DS" "$JAC_REPO" <<'PYEOF'
import json, subprocess, sys, tempfile, os
from pathlib import Path
work, cand, ds, jac_repo = sys.argv[1:5]
meta = {}
for f in Path(work).glob("*.json"):
    if f.name == "report.json": continue
    r = json.load(open(f)); meta[r["id"]] = r
kept = drop = rej = 0
with open(ds, "w") as out:
    for line in open(cand):
        line = line.strip()
        if not line: continue
        c = json.loads(line)
        code = c.get("candidate")
        if not code or code == "REJECT":
            rej += 1; continue
        with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
            tf.write(code); tp = tf.name
        try:
            p = subprocess.run(["jac", "check", tp], cwd=jac_repo,
                               capture_output=True, timeout=90)
        finally:
            os.unlink(tp)
        if p.returncode != 0:
            drop += 1; continue
        m = meta.get(c["id"], {})
        out.write(json.dumps({
            "id": c["id"], "repo": m.get("repo"), "path": m.get("path"),
            "commit": m.get("commit"), "spdx": m.get("spdx"),
            "status_in": m.get("status"), "source": "js2jac_cleaned",
            "js": m.get("source_js"), "jac": code,
        }) + "\n"); kept += 1
print(f"  guard: kept {kept}, check-fail {drop}, rejected {rej}")
PYEOF

$PY - "$DS" "$MASTER" "$TAG" <<'PYEOF'
import json, sys, os
ds, master, tag = sys.argv[1:4]
rows = [json.loads(l) for l in open(ds)]
seen = set()
if os.path.exists(master):
    for l in open(master): seen.add(json.loads(l)["id"])
added = 0
with open(master, "a") as fh:
    for r in rows:
        if r["id"] not in seen:
            r["chunk"] = tag; fh.write(json.dumps(r) + "\n"); added += 1
print(f"  appended {added} new records to {master} (total now {len(seen)+added})")
PYEOF

rm -rf "$WORK/_emitted" 2>/dev/null || true
echo "[$TAG] DONE"
