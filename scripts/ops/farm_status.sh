#!/usr/bin/env bash
# farm_status.sh — one-shot health check of the jac_llm_data farm grid.
# Read-only. Run from anywhere: bash ~/repos/jac_llm_data/scripts/ops/farm_status.sh
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
DATA=data

echo "=== FARM STATUS $(date '+%F %T') ==="

# --- running processes -------------------------------------------------------
echo "" && echo "-- active pipeline processes --"
if pgrep -af "step4|idiomize|py2jac|composer|floorfix|reguard|rescue" 2>/dev/null | grep -v pgrep | grep -v farm_status; then
    :
else
    echo "  (none running)"
fi

# --- chunks -------------------------------------------------------------------
echo "" && echo "-- farm_chunks --"
CHUNKS=$(find "$DATA/farm_chunks" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
if [ -z "$CHUNKS" ]; then
    echo "  (no chunks)"
fi
for c in $CHUNKS; do
    name=$(basename "$c")
    cand="$c/candidates.jsonl"
    work="$c/work"
    total=0; [ -f "$cand" ] && total=$(wc -l < "$cand")
    done_n=$(find "$work" -name '*.json' 2>/dev/null | wc -l)
    pct=0; [ "$total" -gt 0 ] && pct=$((done_n * 100 / total))
    # last modified in chunk = liveness signal
    if [ -d "$work" ]; then
        last=$(find "$work" -name '*.json' -newermt '-10 minutes' 2>/dev/null | head -1)
        [ -n "$last" ] && live="LIVE" || live="idle"
        age=$(find "$work" -name '*.json' -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
    else
        live="no-work-dir"; age=""
    fi
    printf "  %-14s %5d/%-6d (%3d%%)  %s\n" "$name" "$done_n" "$total" "$pct" "$live"
done

# --- master datasets -----------------------------------------------------------
echo "" && echo "-- master datasets (line counts) --"
for f in "$DATA"/*dataset*.jsonl; do
    [ -f "$f" ] && printf "  %-45s %8d\n" "$(basename "$f")" "$(wc -l < "$f")"
done

# --- recent log tails: catch silent death -------------------------------------
echo "" && echo "-- newest logs (mtime) --"
ls -t "$DATA"/*.log 2>/dev/null | head -5 | while read -r f; do
    printf "  %-40s %s  last: %s\n" "$(basename "$f")" "$(date -r "$f" '+%F %T')" \
        "$(tail -1 "$f" | tr -d '\n' | cut -c1-100)"
done

# --- wedged check: no live chunk + no processes but incomplete chunks ----------
RUNNING=$(pgrep -fc "step4|idiomize|py2jac|composer|floorfix|reguard|rescue" 2>/dev/null || echo 0)
INCOMPLETE=$(for c in $CHUNKS; do
    cand="$c/candidates.jsonl"; work="$c/work"
    total=0; [ -f "$cand" ] && total=$(wc -l < "$cand")
    done_n=$(find "$work" -name '*.json' 2>/dev/null | wc -l)
    [ "$done_n" -lt "$total" ] && echo x
done | wc -l)
if [ "$RUNNING" -eq 0 ] && [ "$INCOMPLETE" -gt 0 ]; then
    echo "" && echo "⚠️  WEDGED? $INCOMPLETE incomplete chunk(s) but zero pipeline processes running."
fi

echo "" && echo "=== end ==="
