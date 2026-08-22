#!/usr/bin/env bash
# Resume both composer grinds after the 2026-08-16 19:25 tmux-server crash.
#
#   Phase A: py2jac  composer_grind.sh 19000 2000   (master 14356 -> 15000)
#   Phase B: js2jac  js2jac_grind.sh   0 20         (runs sequentially)
#
# Run DETACHED so a tmux-server death cannot kill it:
#   setsid nohup bash scripts/resume_both.sh >/dev/null 2>&1 &
#
# - Both grinders are resume-safe (chunks with dataset.jsonl are skipped).
# - Watchdog: a phase is STALLED only if (a) its log is silent > SILENT_S and
#   (b) its process group gained zero CPU between checks (guard stages are
#   silent by design, so CPU is the truth signal). On stall: kill the pg,
#   purge the embedded-postgres codespace (known wedge), restart, notify.
#   Max RESTARTS per phase, then give up + notify.
set -um   # -m: each background job gets its own pgid (lets us kill the tree)

cd "$(dirname "$0")/.."
PYLOG=data/composer_grind.log
JSLOG=scripts/js2jac_dataset/runs/js2jac_grind.log
RLOG=data/resume_both.log
SILENT_S=${SILENT_S:-5400}     # 90 min log silence before suspicion
RESTARTS=${RESTARTS:-3}

log(){ echo "[$(date '+%F %T')] $*" | tee -a "$RLOG"; }
note(){ notify-send -u critical -t 0 "$1" "$2" 2>/dev/null || true; log "NOTIFY: $1 :: $2"; }

pg_cpu(){  # total CPU seconds of a pgid (0 if none)
  ps -eo pgid=,times= 2>/dev/null | awk -v p="$1" '$1==p{s+=$2} END{print int(s+0)}'
}
purge_pg(){  # known wedge: corrupted embedded-postgres codespace
  pkill -9 -f 'postgres .*jacpg' 2>/dev/null
  rm -rf "$HOME/.cache/jac/pg" /tmp/jacpg-* 2>/dev/null
  log "codespace purged"
}

run_phase(){  # name logfile cmd...
  local name="$1" logf="$2"; shift 2
  local tries=0 pid stalled cpu_a cpu_b idle
  while true; do
    stalled=0; cpu_a=""; 
    log "PHASE $name: launching: $*"
    "$@" >> "$logf" 2>&1 &
    pid=$!
    log "PHASE $name: pid=$pid pgid=$(ps -o pgid= -p "$pid" | tr -d ' ')"
    while kill -0 "$pid" 2>/dev/null; do
      sleep 300
      kill -0 "$pid" 2>/dev/null || break
      cpu_b=$(pg_cpu "$pid")
      idle=$(( $(date +%s) - $(stat -c %Y "$logf" 2>/dev/null || date +%s) ))
      if [ "$idle" -gt "$SILENT_S" ] && [ -n "$cpu_a" ] && [ "$cpu_b" = "$cpu_a" ]; then
        stalled=1
        log "PHASE $name: STALLED (silent ${idle}s, cpu ${cpu_a}s->${cpu_b}s) — killing + purge"
        note "$name grind STALLED" "silent ${idle}s, zero CPU; auto-restart #$((tries+1))"
        kill -TERM -- -"$pid" 2>/dev/null; sleep 15; kill -KILL -- -"$pid" 2>/dev/null
        purge_pg
        break
      fi
      cpu_a="$cpu_b"
    done
    if [ "$stalled" -eq 1 ]; then
      tries=$((tries+1))
      [ "$tries" -ge "$RESTARTS" ] && { note "$name grind GAVE UP" "$RESTARTS stalls — needs a human"; return 1; }
      continue
    fi
    wait "$pid"; local rc=$?
    log "PHASE $name: exited rc=$rc"
    return 0
  done
}

# --- guard against double-launch ---
LOCKF=/tmp/resume_both.lock
exec 8>"$LOCKF" || exit 1
flock -n 8 || { log "already running — refusing to double-launch"; exit 1; }

log "=== resume_both start (tmux-crash recovery) ==="
note "grinds resuming" "py2jac chunk_19000 first, then js2jac — sequential"

run_phase py2jac "$PYLOG" bash scripts/composer_grind.sh 19000 2000
PN=$(wc -l < data/composer_dataset.jsonl 2>/dev/null || echo '?')
note "py2jac grind FINISHED" "master=${PN}/15000 — starting js2jac next"

run_phase js2jac "$JSLOG" bash scripts/js2jac_dataset/js2jac_grind.sh 0 20
JN=$(wc -l < scripts/js2jac_dataset/js2jac_dataset.jsonl 2>/dev/null || echo '?')
note "ALL GRINDS FINISHED" "py2jac master=${PN}/15000, js2jac master=${JN}"
log "=== resume_both end ==="
