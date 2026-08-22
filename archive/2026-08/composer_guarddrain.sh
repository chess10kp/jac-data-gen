#!/usr/bin/env bash
# Guard drainer (parallel): wait for the in-flight chunk_11000 guard ($1) to
# finish, then for each offset launch a guard-recover as soon as that chunk's
# composer candidates are ready. Guards run CONCURRENTLY — safe because
# composer_guard_recover.py now appends each record with a single atomic
# os.write() to an O_APPEND master fd, and chunk id-spaces are disjoint.
#
# Usage: composer_guarddrain.sh <pid_to_wait_for> <offset> [<offset> ...]
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
MASTER=data/composer_dataset.jsonl
WORKERS_PER_RUN="${GUARD_WORKERS:-4}"   # ~4 jac workers x N concurrent runs coexists w/ prep on 16 cpus
WAIT_PID="${1:?usage: composer_guarddrain.sh <wait_pid> <offset...>}"; shift
prepped() { find "$1" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l; }

echo "[drain] waiting for in-flight guard PID $WAIT_PID..."
while kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
echo "[drain] PID $WAIT_PID done $(date '+%T') — master $(wc -l < "$MASTER")"

# One background waiter+guard per chunk; they run concurrently.
pids=()
for OFFSET in "$@"; do
  TAG="chunk_${OFFSET}"; RTAG="rec_${OFFSET}"
  WORK="data/chunks/${TAG}/work"; CAND="data/chunks/${TAG}/candidates.jsonl"
  LOG="data/chunks/${TAG}/guard.log"; TMP="/tmp/jactmp_${TAG}_g"
  mkdir -p "data/chunks/${TAG}"
  (
    n=$(prepped "$WORK")
    [ "$n" -eq 0 ] && { echo "[drain $TAG] no work — skip"; exit 0; }
    # wait until composer has produced candidates for all work records.
    # Breakout: if the candidate count stops growing for STALE_CHK checks AND
    # some candidates exist, the composer finished/stalled (a few records always
    # fail to parse) — proceed; guard-recover falls back to floor for missing ids.
    echo "[drain $TAG] waiting for candidates ($n expected)..."
    stale=0; prev=-1; STALE_CHK=4
    while true; do
      ncand=0; [ -f "$CAND" ] && ncand=$(wc -l < "$CAND")
      [ "$ncand" -ge "$n" ] && break
      if [ "$ncand" = "$prev" ]; then stale=$((stale+1)); else stale=0; fi
      prev=$ncand
      if [ "$ncand" -gt 0 ] && [ "$stale" -ge "$STALE_CHK" ]; then
        echo "[drain $TAG] candidates stalled at $ncand/$n — proceeding (floor fallback)"
        break
      fi
      sleep 60
    done
    echo "[drain $TAG] candidates ready ($(wc -l < "$CAND")/$n) — guard-recover start $(date '+%T')"
    mkdir -p "$TMP"
    TMPDIR="$TMP" $PY scripts/composer_guard_recover.py \
      --work-dir "$WORK" --candidates "$CAND" --tag "$RTAG" \
      --sub-batch 100 --workers "$WORKERS_PER_RUN"
    rm -rf "$TMP"
    echo "[drain $TAG] DONE $(date '+%T') — master $(wc -l < "$MASTER")"
  ) >>"$LOG" 2>&1 &
  pids+=($!)
  echo "[drain] launched $TAG guard (bg PID ${pids[-1]})"
done

echo "[drain] waiting on ${#pids[@]} parallel guards..."
fail=0
for p in "${pids[@]}"; do wait "$p" || fail=$((fail+1)); done
mn=$(wc -l < "$MASTER" 2>/dev/null || echo 0)
echo "[drain] ALL DONE $(date '+%T') — master $mn ($fail guards failed)"
