#!/usr/bin/env bash
# Composer feeder: for each offset, prep -> pack -> composer. NO guard (the
# guard drainer handles master appends separately). Composer runs are serialized
# via /tmp/composer.lock so only one cursor-agent driver runs at a time.
# Usage: composer_feeder.sh <offset> [<offset> ...]
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
SIZE=2000
JACTMP="${JACTMP_ROOT:-data/tmp/jactmp}"
mkdir -p "$JACTMP"
prepped() { find "$1" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l; }

for OFFSET in "$@"; do
  TAG="chunk_${OFFSET}"
  WORK="data/chunks/${TAG}/work"; BATCH="data/chunks/${TAG}/batches"
  CAND="data/chunks/${TAG}/candidates.jsonl"; TMP="${JACTMP}/${TAG}"
  echo "[feed] === $TAG $(date '+%T') ==="

  # 1. prep (skip if already prepped)
  mkdir -p "$WORK"; n=$(prepped "$WORK")
  if [ "$n" -lt 50 ]; then
    echo "[feed] $TAG prep (offset=$OFFSET limit=$SIZE)"
    mkdir -p "$TMP"
    TMPDIR="$TMP" $PY scripts/agent_idiomize_prep.py \
      --offset "$OFFSET" --limit "$SIZE" --workers "${PREP_WORKERS:-8}" \
      --work-dir "$WORK" --shared-tmp "$TMP" \
      2>&1 | grep -v "cached\|Found the latest" || true
    rm -rf "$TMP"; n=$(prepped "$WORK")
    echo "[feed] $TAG prepped $n"
    [ "$n" -eq 0 ] && { echo "[feed] $TAG empty — end of dataset, skipping"; continue; }
  else
    echo "[feed] $TAG prep already done ($n)"
  fi

  # 2. pack batches (10 records each)
  mkdir -p "$BATCH"
  $PY - "$WORK" "$BATCH" <<'PY'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json"))); B = 10
for i in range(0, len(files), B):
    recs = [{k: json.load(open(f))[k] for k in ("id","entrypoint","floor_fn","python")}
            for f in files[i:i+B]]
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs))
print(f"  {len(files)} -> {(len(files)+B-1)//B} batches")
PY

  # 3. composer (skip if already complete). Serialized via composer lock.
  ncand=0; [ -f "$CAND" ] && ncand=$(wc -l < "$CAND")
  if [ "$ncand" -lt "$n" ]; then
    echo "[feed] $TAG composer ($ncand/$n) — acquiring composer lock"
    (
      flock -w 21600 9 || { echo "[feed] $TAG composer lock failed"; exit 4; }
      $PY scripts/cursor_composer_batch.py --batch-dir "$BATCH" --out "$CAND" \
        --model composer-2.5 --workers 6 --timeout 360
    ) 9>/tmp/composer.lock
  else
    echo "[feed] $TAG composer complete ($ncand) — skip"
  fi
  echo "[feed] $TAG candidates: $(wc -l < "$CAND" 2>/dev/null || echo 0)/$n ($(date '+%T'))"
done
echo "[feed] ALL DONE $(date '+%T')"
