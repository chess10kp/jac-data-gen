#!/usr/bin/env bash
# Full FARM dataset generation run: discover -> refresh chunk prep -> grind.
# The 40-model pool was exhausted on 08-17, so stage-0 discovery appends NEW
# model files (dedup by id) first, then we refresh chunk_0's prep so the new
# nodes enter the pipeline (farm_chunk.sh only preps an EMPTY work dir), then
# hand off to farm_grind.sh which resumes/skips by .done + candidate ids.
# Safe to re-run at any point; every stage is idempotent or resume-safe.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
cd "$ROOT"

MODELS="${1:-scripts/js2jac_dataset/farm_models.jsonl}"
LIMIT="${2:-200}"

echo "=== farm full run start $(date '+%F %T') (limit $LIMIT) ==="

# stage 0: discover new model files (beanie,odmantic,mongoengine; appends, dedups)
python3 scripts/js2jac_dataset/farm/discover.py --out "$MODELS" --limit "$LIMIT"
rc=$?
echo "[full] discover rc=$rc — models file now: $(wc -l < "$MODELS") files"

# refresh chunk_0 prep over the (possibly grown) models file; idempotent writes
python3 scripts/js2jac_dataset/farm/prep.py \
  --models "$MODELS" --offset 0 --limit 500 \
  --work-dir archive/2026-09/scratch/farm_chunks/chunk_0/work
rm -f archive/2026-09/scratch/farm_chunks/chunk_0/.done

# stage 1+: grind chunks to end of models file
bash scripts/js2jac_dataset/farm/grind.sh 0 500 "$MODELS"
echo "=== farm full run end $(date '+%F %T') ==="
