#!/usr/bin/env bash
# Reclaim jac's embedded-postgres cache (~/.cache/jac/pg).
#
# Two modes:
#  ONLINE (primary): a live embedded PG (socket /tmp/jacpg-*) is running —
#    drop idle per-invocation scratch DBs (jac_main_*) over the wire. Safe
#    while pipelines run: DBs with active connections are skipped, plain
#    DROP DATABASE fails safely on race, and DBs younger than AGE_MIN are
#    left alone (fresh test DBs).
#  OFFLINE (fallback): no live PG — rm -rf the whole cache dir once it
#    exceeds THRESH_MB (jac re-runs initdb on next boot). Kept from the
#    original wiper; still gated on no pipeline drivers for politeness.
#
# Leak: jac creates one ~9MB database per `jac test` invocation and never
# drops it. A 2000-record chunk leaks ~18G. Aug 18 (44G) and Aug 19 (disk
# full, killed the mut rerun) were both this leak.
set -u

CACHE="$HOME/.cache/jac/pg"
LOG="$HOME/.cache/jac/pg_wiper.log"
THRESH_MB=2048     # offline rm -rf threshold
AGE_MIN=0     # safe: busy-skip via active-connection check is the real guard
PY="$HOME/repos/jac_llm_data/.venv/bin/python"
[ -x "$PY" ] || PY=$(command -v python3)

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }
[ -d "$CACHE" ] || exit 0

SOCK=$(ls -d /tmp/jacpg-* 2>/dev/null | head -1)

if [ -n "$SOCK" ] && pgrep -u "$USER" -x postgres >/dev/null 2>&1; then
  # ---- ONLINE: drop idle scratch DBs on the live cluster ----
  OUT=$("$PY" "$HOME/repos/jac_llm_data/scripts/ops/pg_drop_idle.py" "$AGE_MIN" 2>&1)
  case "$OUT" in
    OK*) log "online: $OUT" ;;
    "")  log "online: no writable cluster found" ;;
    *)   log "online error: $(echo "$OUT" | tail -1)" ;;
  esac
  exit 0
fi

# ---- OFFLINE: no live PG — wipe the whole cache dir if oversized ----
if pgrep -u "$USER" -f 'oxalpha_free_generate|reguard_paid|agent_idiomize_guard|js2jac_grind|js2jac_chunk|py2jac_dogfood|finish_to_15k|dataset-farm|rescue_watch|rerun_mut' >/dev/null 2>&1; then
  log "skip offline wipe: pipeline driver alive"
  exit 0
fi
size_mb=$(du -sm "$CACHE" 2>/dev/null | awk '{print $1}')
[ -n "$size_mb" ] || exit 0
if [ "$size_mb" -lt "$THRESH_MB" ]; then exit 0; fi
before=$(df --output=avail -m "$HOME" | tail -1)
rm -rf "$CACHE"
after=$(df --output=avail -m "$HOME" | tail -1)
log "offline wipe: ${size_mb}MB (disk free ${before}MB -> ${after}MB)"
