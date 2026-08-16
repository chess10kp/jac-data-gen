#!/usr/bin/env bash
# Run all reguard shards to completion, then merge into master.
set -uo pipefail
cd "$(dirname "$0")/.."
PY=.venv/bin/python
LOG=data/reguard_run.log
echo "=== $(date '+%F %T') reguard wrapper start (master=$(wc -l < data/composer_dataset.jsonl)) ===" >> "$LOG"

bash scripts/reguard_floors_parallel.sh 4 4 >> "$LOG" 2>&1

# wait for all shard processes to finish
while pgrep -f 'scripts/reguard_floors.py' > /dev/null; do sleep 60; done
echo "=== $(date '+%F %T') all shards done — merging ===" >> "$LOG"
$PY scripts/reguard_floors.py --merge >> "$LOG" 2>&1
echo "=== $(date '+%F %T') merge rc=$? ===" >> "$LOG"
$PY - <<'EOF' >> "$LOG" 2>&1
import json, collections
c = collections.Counter(json.loads(l).get('source') for l in open('data/composer_dataset.jsonl'))
print('final master:', dict(c))
EOF
echo "=== $(date '+%F %T') reguard wrapper done ===" >> "$LOG"
