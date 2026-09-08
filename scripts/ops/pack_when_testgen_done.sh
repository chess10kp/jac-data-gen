#!/usr/bin/env bash
# Wait for the testgen luna wave to finish, then re-pack the test-verified
# gold slice and ping the desktop. Also pings critical if the wave dies
# without producing the pack. Usage: run detached alongside the wave.
set -u
cd "$(dirname "$0")/../.."
LOG=data/pack_watch.log
echo "=== pack watcher start $(date '+%F %T') ===" >>"$LOG"

before=$(wc -l < data/osp_dataset_pass.jsonl 2>/dev/null || echo 0)

while pgrep -f 'run_testgen_luna_wave\.sh' >/dev/null 2>&1; do sleep 120; done

python3 scripts/gen/pack_tested_pass.py >>"$LOG" 2>&1
rc=$?
after=$(wc -l < data/osp_dataset_pass.jsonl 2>/dev/null || echo 0)

if [[ $rc -eq 0 && "$after" -gt 0 ]]; then
    bash scripts/ops/notify.sh "✅ OSP gold slice re-packed" \
        "testgen wave done: osp_dataset_pass.jsonl ${before} -> ${after} records"
    echo "[OK] $(date '+%T') packed ${before} -> ${after}" >>"$LOG"
else
    bash scripts/ops/notify.sh "🚨 OSP gold re-pack FAILED" \
        "testgen wave exited but pack_tested_pass rc=$rc (pass file: ${after}). Check data/pack_watch.log + data/testgen_luna_wave.log" critical
    echo "[FAIL] $(date '+%T') rc=$rc after=$after" >>"$LOG"
fi
