#!/usr/bin/env bash
# CI shard for trajectory generation: the teacher (GLM via z.ai, ZAI_API_KEY from
# the repo secret) solves validated agent tasks inside the vendored pinned
# pi-jac-ast-edit deploy harness; sessions are recorded + graded.
# Run parameters come from .ci/agent-tasks/traj.env (TRAJ_MODE, TRAJ_KINDS, ...).
# NEVER `set -x` here: the environment holds the API key.
set -euo pipefail
cd "$GITHUB_WORKSPACE"
OUTD="$GITHUB_WORKSPACE/$OUT"
mkdir -p "$OUTD"

TRAJ_MODE=run TRAJ_KINDS=native,app TRAJ_K=2 TRAJ_LIMIT=0 TRAJ_ONLY= TRAJ_TIMEOUT=20 TRAJ_CONC=3
TRAJ_SANITY_KINDS= TRAJ_SANITY_PER_KIND=3 TRAJ_MODEL=zai/glm-5.3-flash TRAJ_SANDBOX=auto
[ -f .ci/agent-tasks/traj.env ] && . .ci/agent-tasks/traj.env
PY="$GITHUB_WORKSPACE/.venv/bin/python"
SHARED="$HOME/traj_shared_cache"; ROOT="$HOME/traj_sessions"
H="$GITHUB_WORKSPACE/vendor/pi-jac-ast-edit"
echo "traj: mode=$TRAJ_MODE kinds=$TRAJ_KINDS k=$TRAJ_K limit=$TRAJ_LIMIT only=$TRAJ_ONLY shard=$SHARD/$NSHARDS"
[ -n "${ZAI_API_KEY:-}" ] && echo "ZAI_API_KEY present (${#ZAI_API_KEY} chars)" || echo "ZAI_API_KEY MISSING"

# ---- sandbox: bubblewrap (Ubuntu 24.04 restricts unprivileged userns via AppArmor)
if [ "$TRAJ_SANDBOX" != none ]; then
  (sudo apt-get install -y -qq bubblewrap >/dev/null 2>&1 \
   && sudo sysctl -q -w kernel.apparmor_restrict_unprivileged_userns=0) || echo "bwrap setup failed"
fi

# ---- harness: pi + the extension's python engine
npm i -g --silent @earendil-works/pi-coding-agent@0.84.3 >/dev/null
echo "pi $(pi --version) node $(node --version)"
( cd "$H" && python3 -m venv .venv && .venv/bin/pip install -q "tree-sitter>=0.25,<0.27" setuptools pytest \
  && .venv/bin/pip install -q -e ./python )
cat "$H/VENDORED.json"
# e2e: deploy/jacpi.sh against a fake local model (extension loads, typebox resolves, snapshot recorded)
( cd "$H" && JAC_AST_EDIT_CACHE_DIR="$RUNNER_TEMP/astcache" JAC_CACHE_HOME="$SHARED" \
  .venv/bin/python -m pytest -q tests/test_e2e_pi.py 2>&1 | tail -3 ) | tee "$OUTD/harness_e2e.txt"
grep -q "1 passed" "$OUTD/harness_e2e.txt" || { echo "harness e2e failed"; exit 1; }

# ---- shared jac cache + isolation probe (fail before spending API calls)
"$PY" scripts/agent_tasks/traj_run.py prewarm --shared "$SHARED" --root "$ROOT"
"$PY" scripts/agent_tasks/traj_run.py probe --shared "$SHARED" --root "$ROOT" --sandbox "$TRAJ_SANDBOX" \
  | tee "$OUTD/probe.txt"
grep -q "PROBE PASS" "$OUTD/probe.txt" || { echo "isolation probe failed"; exit 1; }

# ---- grader sanity: reference passes, starter fails (a few tasks per kind)
if [ -n "$TRAJ_SANITY_KINDS" ]; then
  IFS=, read -ra SK <<< "$TRAJ_SANITY_KINDS"
  k="${SK[$((SHARD % ${#SK[@]}))]}"   # one kind per shard
  JAC_CACHE_HOME="$SHARED" env -u ZAI_API_KEY "$PY" scripts/agent_tasks/grade.py --sanity --kinds "$k" \
    --per-kind "$TRAJ_SANITY_PER_KIND" --out "$OUTD/sanity.jsonl" || echo "SANITY had failures"
fi

rc=0
if [ "$TRAJ_MODE" = run ]; then
  "$PY" scripts/agent_tasks/traj_run.py run --shared "$SHARED" --root "$ROOT" --sandbox "$TRAJ_SANDBOX" \
    --shard "$SHARD/$NSHARDS" --out "$OUTD" --kinds "$TRAJ_KINDS" --k "$TRAJ_K" --limit "$TRAJ_LIMIT" \
    ${TRAJ_ONLY:+--only "$TRAJ_ONLY"} --model "$TRAJ_MODEL" --timeout "$TRAJ_TIMEOUT" --concurrency "$TRAJ_CONC" || rc=$?
fi

# ---- last line of defence: no output file may contain the key
"$PY" - "$OUTD" <<'EOF' || rc=4
import gzip, os, sys
from pathlib import Path
key = os.environ.get("ZAI_API_KEY", "").encode()
bad = []
if len(key) >= 8:
    for p in Path(sys.argv[1]).rglob("*"):
        if p.is_file():
            d = p.read_bytes()
            if p.suffix == ".gz":
                try: d += gzip.decompress(d)
                except Exception: pass
            if key in d:
                bad.append(p); p.write_bytes(b"")  # emptied (shard log is still open by tee)
                if not p.name.startswith("shard_"): p.unlink()
print(f"key scan: {len(bad)} file(s) held the key" + (f": {[b.name for b in bad]}" if bad else ""))
sys.exit(1 if bad else 0)
EOF
exit $rc
