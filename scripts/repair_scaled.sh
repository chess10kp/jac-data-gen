#!/usr/bin/env bash
# Scaled repair pass: virgin MultiPL-T band starting right after the prototype
# (seen-offset 430). collect -> compose -> guard, all resumable.
# 900 collected @ ~86% rescue -> ~774 passers vs 644 needed for 15k.
set -u
cd "$(dirname "$0")/.."
OUT=data/chunks/repair_scaled
PY=".venv/bin/python scripts/repair_pass.py"
mkdir -p "$OUT"

echo "=== $(date) collect ===" | tee -a "$OUT/run.log"
$PY collect --out-dir "$OUT" --offset 430 --limit 900 --workers 6 \
  >> "$OUT/run.log" 2>&1 || echo "collect rc=$?" | tee -a "$OUT/run.log"

echo "=== $(date) compose ===" | tee -a "$OUT/run.log"
$PY compose --out-dir "$OUT" --workers 4 --model composer-2.5 --timeout 360 \
  >> "$OUT/run.log" 2>&1 || echo "compose rc=$?" | tee -a "$OUT/run.log"

echo "=== $(date) guard (test timeout 300s) ===" | tee -a "$OUT/run.log"
$PY guard --out-dir "$OUT" --workers 4 --test-timeout 300 \
  >> "$OUT/run.log" 2>&1 || echo "guard rc=$?" | tee -a "$OUT/run.log"

echo "=== $(date) done ===" | tee -a "$OUT/run.log"
python3 - "$OUT" <<'EOF' >> "$OUT/run.log" 2>&1
import json, sys, collections
c = collections.Counter()
for ln in open(sys.argv[1] + "/repaired.jsonl"):
    if ln.strip(): c[json.loads(ln)["outcome"]] += 1
print("final tallies:", dict(c))
EOF
