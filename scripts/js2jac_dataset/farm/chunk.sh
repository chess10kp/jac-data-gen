#!/usr/bin/env bash
# One FARM burndown chunk: prep -> pack -> composer -> guard -> master append.
# Mirrors composer_chunk.sh. Resume-safe (skips prep/composer already done).
# rc=3 => prep produced no records (end of models file) -> grind stops.
# Usage: farm_chunk.sh <offset> [size] [models.jsonl] [master.jsonl]
# Env:   MODEL (composer-2.5) WORKERS (6) TIMEOUT (360) PY (python3)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
cd "$ROOT"

OFFSET="${1:?offset required}"; SIZE="${2:-500}"
MODELS="${3:-scripts/js2jac_dataset/farm_models.jsonl}"
MASTER="${4:-data/farm_dataset.jsonl}"
PY="${PY:-python3}"
TAG="chunk_${OFFSET}"
DIR="archive/2026-09/scratch/farm_chunks/${TAG}"
WORK="$DIR/work"; BATCH="$DIR/batches"; CAND="$DIR/candidates.jsonl"
mkdir -p "$WORK" "$BATCH"

# 1. prep (skip if already prepped). PREP=handler uses whole-app bundles +
#    real routes/db as translation context; default = schema-only CRUD authoring.
n=$(find "$WORK" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l)
if [ "$n" -eq 0 ]; then
  if [ "${PREP:-schema}" = "handler" ]; then
    "$PY" scripts/js2jac_dataset/farm_handler_prep.py \
      --bundles "$MODELS" --offset "$OFFSET" --limit "$SIZE" --work-dir "$WORK"
  else
    "$PY" scripts/js2jac_dataset/farm/prep.py \
      --models "$MODELS" --offset "$OFFSET" --limit "$SIZE" --work-dir "$WORK"
  fi
  [ "$?" -eq 3 ] && { echo "[farm] $TAG: prep empty — end of input"; exit 3; }
  n=$(find "$WORK" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l)
fi
echo "[farm] $TAG prepped $n node-records"
[ "$n" -eq 0 ] && exit 3

# 2. pack batches of 10 (only the keys the composer prompt needs)
"$PY" - "$WORK" "$BATCH" <<'PYEOF'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json"))); B = 10
KEYS = ("id", "node", "archetype", "tag_field", "bool_field", "update_field", "scalar_fields")
OPT = ("handler_context",)   # present only for handler-translation prep
for i in range(0, len(files), B):
    recs = []
    for f in files[i:i+B]:
        d = json.load(open(f))
        rec = {k: d[k] for k in KEYS}
        rec.update({k: d[k] for k in OPT if k in d})
        recs.append(rec)
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(json.dumps(recs))
print(f"  {len(files)} -> {(len(files)+B-1)//B} batches")
PYEOF

# 3. composer (skip if complete). Free-gateway models (*-free, unlimited
# throughput) run without the global lock; cursor-agent models serialize.
ncand=0; [ -f "$CAND" ] && ncand=$(wc -l < "$CAND")
MODEL="${MODEL:-x-preview-f-free}"
if [ "$ncand" -lt "$n" ]; then
  if [[ "$MODEL" == *-free ]]; then
    echo "[farm] $TAG composer ($ncand/$n) — free gateway, no lock"
    "$PY" scripts/js2jac_dataset/farm/composer.py \
      --batch-dir "$BATCH" --out "$CAND" \
      --model "$MODEL" --workers "${WORKERS:-6}" --timeout "${TIMEOUT:-360}"
  else
    echo "[farm] $TAG composer ($ncand/$n) — acquiring composer lock"
    (
      flock -w 21600 9 || { echo "[farm] $TAG composer lock failed"; exit 4; }
      "$PY" scripts/js2jac_dataset/farm/composer.py \
        --batch-dir "$BATCH" --out "$CAND" \
        --model "$MODEL" --workers "${WORKERS:-6}" --timeout "${TIMEOUT:-360}"
    ) 9>/tmp/composer.lock
  fi
else
  echo "[farm] $TAG composer complete ($ncand) — skip"
fi

# 4. guard -> master (behavioral gate is the arbiter)
"$PY" scripts/js2jac_dataset/farm/guard.py \
  --work-dir "$WORK" --candidates "$CAND" --out "$MASTER"
echo "[farm] $TAG done; master: $(wc -l < "$MASTER" 2>/dev/null || echo 0)"
