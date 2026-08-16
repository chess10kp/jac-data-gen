#!/usr/bin/env bash
# Watcher: wait until the composer pipeline (feeder + guarddrain + all
# workers) has fully exited, reclaim the jac program cache that the live run
# filled (~62G under ~/.cache/jac/pg — only safe to clear once no jac test
# worker is running), then launch the full convertible harvest.
#
# Gates the harvest launch on >= MIN_FREE_GB free on / so it can never fill
# the disk. Logs everything to runs/harvest_watcher.log.
#
# Usage: nohup bash scripts/harvest_after_composer.sh &
set -uo pipefail
cd "$(dirname "$0")/.."
SOURCE=scripts/js2jac_dataset/source
WATCH_LOG="$SOURCE/runs/harvest_watcher.log"
HARVEST_LOG="$SOURCE/runs/harvest_convertible_full.log"
OUT="$SOURCE/harvest_convertible_full.jsonl"
MIN_FREE_GB=5
PY=python3   # harvest.py is stdlib-only (uses sibling profiles.py)

log() { echo "[$(date '+%F %T')] $*" >> "$WATCH_LOG"; }

log "=== watcher started ==="

# 1. Wait for the composer fleet to be completely gone (robust to PID reuse:
#    poll by command pattern, not fixed PIDs).
log "waiting for composer fleet to exit (feeder + guarddrain + workers)..."
while {
  pgrep -f 'composer_feeder.sh'            ||
  pgrep -f 'composer_guarddrain.sh'        ||
  pgrep -f 'composer_guard_recover.py'     ||
  pgrep -f 'cursor_composer_batch.py'      ||
  pgrep -f 'agent_idiomize_prep.py'        ||
  pgrep -f 'jac test /tmp/jactmp'
} >/dev/null 2>&1; do
  sleep 30
done
log "composer fleet exited. master records: $(wc -l < data/composer_dataset.jsonl)"

# 2. Grace period, then a final no-stragglers confirmation.
sleep 45
if pgrep -f 'jac test /tmp/jactmp' >/dev/null 2>&1; then
  log "WARNING: jac test workers still alive after grace — still proceeding (cache clear skipped)"
  SKIP_CLEAR=1
else
  SKIP_CLEAR=0
fi

# 3. Reclaim jac program cache (only safe with no test workers running).
if [ "$SKIP_CLEAR" -eq 0 ] && [ -d "$HOME/.cache/jac/pg" ]; then
  SZ=$(du -sh "$HOME/.cache/jac/pg" 2>/dev/null | cut -f1)
  log "clearing ~/.cache/jac/pg ($SZ) to reclaim disk"
  rm -rf "$HOME/.cache/jac/pg" 2>>"$WATCH_LOG"
fi
AVAIL_GB=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
log "free on / after reclaim: ${AVAIL_GB}G"

# 4. Free-space gate. Abort launch (do NOT fill the disk) if too tight.
if [ "$AVAIL_GB" -lt "$MIN_FREE_GB" ]; then
  log "ABORT: only ${AVAIL_GB}G free on / (need >= ${MIN_FREE_GB}G). Harvest NOT launched."
  log "Reclaim disk manually, then run: cd $SOURCE && $PY harvest.py --candidates convertible_cands.jsonl --profile convertible --limit 980 --out $(basename "$OUT")"
  exit 3
fi

# 5. Launch the full convertible harvest.
cd "$SOURCE"
log "launching harvest: 980 candidates -> $(basename "$OUT")"
nohup "$PY" harvest.py \
  --candidates convertible_cands.jsonl \
  --profile convertible \
  --limit 980 \
  --out "$(basename "$OUT")" \
  >"$HARVEST_LOG" 2>&1 &
HPID=$!
echo "$HPID" > /tmp/harvest_convertible.pid
log "harvest launched PID=$HPID  log=$HARVEST_LOG"
