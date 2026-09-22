#!/usr/bin/env bash
# One-shot status for the luna idiomize generation pipeline.
# Usage: bash scripts/ops/luna_status.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

# -- driver -----------------------------------------------------------------
if pgrep -f '[o]sp_luna_parallel' >/dev/null 2>&1; then
    info=$(ps -eo etime,cmd --no-headers | grep '[o]sp_luna_parallel' | head -1)
    echo "DRIVER  running (up $(echo "$info" | awk '{print $1}'))"
else
    echo "DRIVER  not running"
fi
echo "MODEL   $(ps -eo cmd --no-headers | grep -c '[p]i -p') luna call(s) in flight"

# -- latest run log ----------------------------------------------------------
LOG=$(ls -t runs/osp_luna_*.log 2>/dev/null | head -1 || true)
if [ -n "$LOG" ]; then
    echo "LOG     $LOG (updated $(date -r "$LOG" '+%H:%M:%S'))"
    head -1 "$LOG" | sed 's/^/        /'
    ok=$(grep -cE '\] .*: OK ' "$LOG" || true)
    fail=$(grep -cE ': FAIL auth' "$LOG" || true)
    done_line=$(grep -m1 'ALL DONE' "$LOG" || true)
    echo "        verdicts: $ok OK / $fail FAIL ${done_line:+— $done_line}"
    tail -2 "$LOG" | sed 's/^/        /'
fi

# -- ledger window (today) ---------------------------------------------------
python3 - <<'EOF'
import json, re
from datetime import datetime, timedelta
from collections import Counter

today = datetime.now().strftime('%Y-%m-%d')
rows = []
for line in open('data/osp_lifts/_gen_failures.jsonl'):
    try: r = json.loads(line)
    except Exception: continue
    t = r.get('ts')
    ts = t if isinstance(t, (int, float)) else datetime.fromisoformat(t).timestamp()
    if datetime.fromtimestamp(ts).strftime('%Y-%m-%d') == today:
        rows.append((ts, r))
if rows:
    stems = {r['stem'] for _, r in rows}
    attempts = Counter(r.get('attempt') for _, r in rows)
    print(f"LEDGER  today: {len(rows)} failed attempts across {len(stems)} records "
          f"(att0: {attempts.get(0,0)}, fixed-retries: {attempts.get(1,0)})"
          + (f", higher: {sum(v for k,v in attempts.items() if k not in (0,1))}" if attempts.get(2) else ""))
    last5 = sorted(rows)[-5:]
    for ts, r in last5:
        e = str(r.get('error',''))
        m = re.search(r'error\[(E\d+)\]', e)
        cls = m.group(1) if m else ('GUARD-TEST' if 'Tests failed' in e else 'semantic')
        print(f"        {datetime.fromtimestamp(ts):%H:%M} {r['stem'][:44]:44s} att{r.get('attempt')} {cls}")
else:
    print("LEDGER  no failed attempts today")
EOF

# -- corpus totals ------------------------------------------------------------
pool=$(ls data/osp_lifts/assignments/issues_*_assign.json 2>/dev/null | wc -l)
jac=$(ls data/osp_lifts/issue_gen/*.jac 2>/dev/null | wc -l)
guards=$(ls data/osp_lifts/issue_gen/*_guard.jac 2>/dev/null | wc -l)
valid=$(python3 -c "print(sum(1 for _ in open('data/osp_lift_dataset.jsonl')))" 2>/dev/null || echo '?')
echo "CORPUS  $pool batches | $jac programs / $guards guard suites authored | $valid packed dataset rows"
