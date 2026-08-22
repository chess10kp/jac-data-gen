#!/usr/bin/env bash
# Driver: mutation-gated re-derivation of ALL bad chunks (rec_9000..rec_17000).
# Order: 17000 first (worst + smallest — fast end-to-end validation), then the
# rest ascending. Each chunk is fully resume-safe; rerun this driver to continue.
set -uo pipefail
# Serial jac test is REQUIRED: jac test defaults to parallel jobs and spawns
# per-core worker processes (~200MB each). 3 pipeline deaths (10:37, 11:47,
# 12:03) were this + launcher shells that never sourced .zshrc's -n0.
export PYTEST_ADDOPTS="${PYTEST_ADDOPTS:--x --maxfail=1 -n0}"
export JAC_TEST_JOBS=0
cd "$(dirname "$0")/.."
for OFF in 17000 9000 11000 13000 15000; do
  free_mb=$(df --output=avail -m . | tail -1)
  if [ "$free_mb" -lt 10240 ]; then
    echo "[driver $(date '+%F %T')] ABORT: only ${free_mb}MB free (<10G) — refusing to start mut_$OFF" >> data/chunks/mut_driver.log
    exit 5
  fi
  echo "[driver $(date '+%F %T')] starting mut_$OFF" >> data/chunks/mut_driver.log
  bash scripts/rerun_mut_chunk.sh "$OFF" 2000
  echo "[driver $(date '+%F %T')] finished mut_$OFF rc=$?" >> data/chunks/mut_driver.log
done
echo "[driver $(date '+%F %T')] ALL CHUNKS DONE" >> data/chunks/mut_driver.log
