#!/usr/bin/env bash
# Mutation-gated re-derivation of one bad chunk: prep_mut -> composer -> guard.
# Usage: rerun_mut_chunk.sh <offset> [limit]
#   - prep: FULL floor guard + mutation gate (weak oracles never reach composer)
#   - composer: fresh composer-2.5 rewrites, strong-oracle records only
#   - guard-drain into the SEPARATE master data/composer_dataset_mut.jsonl
#     under chunk tag mut_<offset> (originals under rec_* stay untouched).
# Resume-safe at every stage (work files, candidates append, guard checkpoint).
set -uo pipefail
# See rerun_mut_all.sh: serial jac test or the worker pool OOMs the box.
export PYTEST_ADDOPTS="${PYTEST_ADDOPTS:--x --maxfail=1 -n0}"
export JAC_TEST_JOBS=0
cd "$(dirname "$0")/.."
PY=.venv/bin/python
WORKERS="${WORKERS:-4}"   # 8 thrashed a 14G box when busy (11.4G peak) — keep low
OFFSET="${1:?offset}"; LIMIT="${2:-2000}"
TAG="mut_${OFFSET}"
WORK="data/chunks/${TAG}/work"
BATCH="data/chunks/${TAG}/batches"
CAND="data/chunks/${TAG}/candidates.jsonl"
MASTER="data/composer_dataset_mut.jsonl"
LOG="data/chunks/${TAG}/run.log"
GATE=0.80
mkdir -p "$WORK" "$BATCH"
exec >>"$LOG" 2>&1
log() { echo "[$(date '+%F %T')] $*"; }

log "=== $TAG start (offset=$OFFSET limit=$LIMIT gate=$GATE) ==="

# 1/4 prep with mutation gate (resume-safe on work files)
log "--- prep_mut ---"
TMPDIR=/tmp $PY scripts/prep_mut.py --offset "$OFFSET" --limit "$LIMIT" \
  --gate "$GATE" --workers "$WORKERS" --work-dir "$WORK" || log "prep_mut rc=$?"

# 2/4 pack batches of 10 — strong-oracle (and unscorable) records ONLY;
# oracle_weak rows skip the composer entirely (floor row later).
log "--- pack (excluding oracle_weak) ---"
$PY - "$WORK" "$BATCH" <<'PYEOF'
import glob, json, os, sys
work, out = sys.argv[1], sys.argv[2]
files = sorted(glob.glob(os.path.join(work, "*.json")))
strong, weak = [], 0
for f in files:
    w = json.load(open(f))
    if w.get("oracle_weak"):
        weak += 1; continue
    strong.append({k: w[k] for k in ("id", "entrypoint", "floor_fn", "python")})
B = 10
n = 0
for i in range(0, len(strong), B):
    open(os.path.join(out, f"batch{i//B:03d}.json"), "w").write(
        json.dumps(strong[i:i+B]))
    n += 1
print(f"  packed {len(strong)} strong-oracle -> {n} batches (skipped {weak} oracle_weak)")
PYEOF

# 3/4 composer (serialized on the shared composer lock)
log "--- composer (composer-2.5) ---"
exec 9>/tmp/composer.lock
flock -w 21600 9 || { log "composer lock failed"; exit 4; }
$PY scripts/cursor_composer_batch.py --batch-dir "$BATCH" --out "$CAND" \
  --model auto --workers 6 --timeout 360
flock -u 9
log "composer done; candidates=$(wc -l < "$CAND" 2>/dev/null || echo 0)"

# 4/4 guard-drain into the mut master (chunk tag mut_<offset>)
log "--- guard-drain -> $MASTER ---"
TMPDIR=/tmp $PY scripts/composer_guard_recover.py \
  --work-dir "$WORK" --candidates "$CAND" --master "$MASTER" \
  --tag "$TAG" --sub-batch 100 --workers 8 || log "guard rc=$?"
log "=== $TAG DONE; mut master=$(wc -l < "$MASTER" 2>/dev/null || echo 0) ==="
