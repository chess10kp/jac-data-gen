#!/usr/bin/env bash
# Bank chunk_0's floor_pass records into the master: pack -> composer -> guard.
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
OFF=0; TAG=chunk_${OFF}; RTAG=rec_${OFF}
WORK=data/chunks/${TAG}/work; BATCH=data/chunks/${TAG}/batches
CAND=data/chunks/${TAG}/candidates.jsonl
MASTER=data/composer_dataset.jsonl
log() { echo "[$(date '+%F %T')] $*"; }

log "=== bank chunk_0 start; master=$(wc -l < "$MASTER") work=$(find "$WORK" -name '*.json' | wc -l) ==="

# 1. pack batches of 10
mkdir -p "$BATCH"
$PY - "$WORK" "$BATCH" <<'PY'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json"))); B = 10
for i in range(0, len(files), B):
    recs = [{k: json.load(open(f))[k] for k in ("id","entrypoint","floor_fn","python")}
            for f in files[i:i+B]]
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs))
print(f"packed {len(files)} -> {(len(files)+B-1)//B} batches")
PY
log "packed"

# 2. composer (serialized via /tmp/composer.lock)
ncand=0; [ -f "$CAND" ] && ncand=$(wc -l < "$CAND")
n=$(find "$WORK" -name '*.json' | wc -l)
if [ "$ncand" -lt "$n" ]; then
  log "composer start ($ncand/$n) — acquiring composer lock"
  (
    flock -w 21600 9 || { log "composer lock failed"; exit 4; }
    $PY scripts/cursor_composer_batch.py --batch-dir "$BATCH" --out "$CAND" \
      --model composer-2.5 --workers 6 --timeout 360
  ) 9>/tmp/composer.lock
else
  log "composer already complete ($ncand)"
fi
log "composer done; candidates=$(wc -l < "$CAND" 2>/dev/null || echo 0)"

# 3. guard-drain into master
rm -rf /tmp/jactmp_${TAG}_g; mkdir -p /tmp/jactmp_${TAG}_g
TMPDIR=/tmp/jactmp_${TAG}_g $PY scripts/composer_guard_recover.py \
  --work-dir "$WORK" --candidates "$CAND" --tag "$RTAG" \
  --sub-batch 100 --workers 4
rm -rf /tmp/jactmp_${TAG}_g
log "=== bank chunk_0 DONE; master=$(wc -l < "$MASTER") ==="
