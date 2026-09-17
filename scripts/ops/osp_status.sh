#!/usr/bin/env bash
# One-shot OSP pipeline status: per-batch progress, active run, pool, cost.
#
# Usage (from anywhere):
#   bash ~/repos/jac_llm_data/scripts/ops/osp_status.sh
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

echo "=== OSP status — $(date '+%F %T') ==="

# ---- active run ------------------------------------------------------------ #
GENS=$(pgrep -f "osp_agent_generate\.py" || true)
if [ -n "$GENS" ]; then
  while read -r GEN; do
    [ -n "$GEN" ] || continue
    CMD=$(ps -o cmd= -p "$GEN" 2>/dev/null || true)
    BATCH=$(printf '%s\n' "$CMD" | sed -n 's/.*--batch \([0-9]*\).*/\1/p')
    [ -n "$BATCH" ] || continue
    ELAPSED=$(ps -o etime= -p "$GEN" | tr -d ' ')
    LOG=$(ls -t "runs/lift_${BATCH}.log" "runs/lift_${BATCH}_glm.log" \
               "runs/glm_${BATCH}.log" "runs/repair2_${BATCH}.log" 2>/dev/null | head -1)
    MODEL="cursor composer-2.5"
    if tr '\0' '\n' < "/proc/$GEN/environ" 2>/dev/null | grep -q "^CURSOR_OSP_MODEL=zai/"; then
      MODEL="zai/glm-5.3-flash"
    fi
    echo "ACTIVE: batch $BATCH on $MODEL (pid $GEN, up ${ELAPSED}) — ${LOG:-no log}"
    [ -n "$LOG" ] && tail -1 "$LOG" | cut -c1-150
  done <<< "$GENS"
else
  echo "ACTIVE: no generation running"
fi
pgrep -f "runs/wave_75_79\.sh" >/dev/null && echo "DRIVER: wave_75_79.sh running"
pgrep -f "runs/repair_round2\.sh" >/dev/null && echo "DRIVER: repair_round2.sh running"

# ---- per-batch table ------------------------------------------------------- #
python3 - "$REPO" <<'EOF'
import json, re, sys, time
from pathlib import Path
ROOT = Path(sys.argv[1])
BASE = ROOT / "data" / "osp_lifts"

rows = []
batches = []
for f in BASE.glob("assignments/issues_*_assign.json"):
    m = re.fullmatch(r"issues_(\d+)_assign\.json", f.name)
    if m:
        batches.append((int(m.group(1)), f))
for b, f in sorted(batches):
    recs = json.loads(f.read_text()).get("records", [])
    man = BASE / f"issues_{b}.jsonl"
    landed = sum(1 for l in man.read_text().splitlines() if l.strip()) if man.exists() else 0
    scores = [int(r.get("score", 0)) for r in recs]
    band = f"{min(scores)}..{max(scores)}" if scores else "-"
    if 75 <= b <= 77:
        note = "v3 falsif / cursor"
    elif b in (78, 79):
        note = "v3 falsif / zai glm"
    elif b >= 56:
        note = "jac-only wave"
    else:
        note = "luna/muse era"
    rows.append((b, len(recs), landed, band, note))

print(f"\n{'batch':>5} {'assign':>6} {'landed':>6} {'rate':>5}  {'band':>7}  note")
tb = ta = 0
for b, n, l, band, note in rows:
    tb += n; ta += l
    print(f"{b:>5} {n:>6} {l:>6} {l/max(1,n)*100:>4.0f}%  {band:>7}  {note}")
if rows:
    print(f"{'TOTAL':>5} {tb:>6} {ta:>6} {ta/max(1,tb)*100:>4.0f}%")

# ---- pool ---------------------------------------------------------------- #
used = set()
for f in BASE.glob("assignments/issues_*_assign.json"):
    for r in json.loads(f.read_text()).get("records", []):
        used.add((r["repo"], int(r["issue"])))
pool8 = total = 0
rp = ROOT / "data" / "graph_targets" / "issues_rescored.jsonl"
if rp.exists():
    for line in rp.read_text().splitlines():
        if not line.strip():
            continue
        h = json.loads(line)
        total += 1
        if int(h.get("score", 0)) < 8:
            continue
        url = h.get("html_url") or ""
        tail = url.split("github.com/")[-1] if "github.com/" in url else (h.get("repo") or "").split("/repos/")[-1]
        key = ("/".join(tail.split("/")[:2]), int(h.get("number", 0)))
        if key not in used:
            pool8 += 1
ds = ROOT / "data" / "osp_lift_dataset.jsonl"
n_ds = sum(1 for l in ds.open() if l.strip()) if ds.exists() else 0
print(f"\nPOOL: {total} rows mined, {pool8} unassigned at score>=8   "
      f"DATASET: {n_ds} rows")

# ---- cost today ----------------------------------------------------------- #
led = BASE / "_cost_ledger.jsonl"
if led.exists():
    today0 = time.mktime(time.strptime(time.strftime("%Y-%m-%d"), "%Y-%m-%d"))
    calls = inp = out = 0
    last = 0.0
    for line in led.read_text().splitlines():
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d.get("ts", 0) >= today0:
            calls += 1
            inp += d.get("input", 0)
            out += d.get("output", 0)
        last = max(last, d.get("ts", 0))
    ago = f"{(time.time() - last)/60:.0f}m ago" if last else "n/a"
    print(f"COST today: {calls} calls, in {inp/1e3:.0f}K out {out/1e3:.0f}K "
          f"(last call {ago})")
EOF
