#!/usr/bin/env bash
# Push the current agent-task work for <kind> to branch agent-tasks/<kind>,
# which triggers .github/workflows/agent-tasks.yml. Uses a separate worktree so
# the main checkout (and other kinds) are untouched. Prints the run URL.
#
# Usage: ci_submit.sh <kind> [extra paths to sync...]
# Always synced: .github/workflows/agent-tasks.yml, .ci/agent-tasks/<kind>.*,
# scripts/agent_tasks/, scripts/lib/, data/agent_tasks/<kind>/.
set -euo pipefail
KIND="$1"; shift
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WT="$REPO/../jac_llm_data-wt/$KIND"
BR="agent-tasks/$KIND"
cd "$REPO"
[ -f ".ci/agent-tasks/$KIND.sh" ] || { echo "missing .ci/agent-tasks/$KIND.sh" >&2; exit 1; }

git fetch -q origin
if [ ! -d "$WT" ]; then
  mkdir -p "$(dirname "$WT")"
  if git ls-remote --exit-code --heads origin "$BR" >/dev/null; then
    git worktree add -q "$WT" -B "$BR" "origin/$BR"
  else
    git worktree add -q "$WT" -B "$BR" origin/master
  fi
fi

paths=(.github/workflows/agent-tasks.yml scripts/agent_tasks scripts/lib "data/agent_tasks/$KIND" "$@")
for p in "${paths[@]}"; do
  [ -e "$p" ] || continue
  mkdir -p "$WT/$(dirname "$p")"
  rsync -a --delete --exclude __pycache__ "$p" "$WT/$(dirname "$p")/"
done
mkdir -p "$WT/.ci/agent-tasks"
cp .ci/agent-tasks/"$KIND".* "$WT/.ci/agent-tasks/"

cd "$WT"
git add -A -f -- "${paths[@]}" .ci/agent-tasks 2>/dev/null || git add -A -f .
if git diff --cached --quiet; then
  echo "nothing changed; re-run with: gh run rerun \$(gh run list -b $BR -L1 --json databaseId -q '.[0].databaseId')"
  exit 0
fi
git commit -q -m "agent-tasks($KIND): submit $(date -u +%FT%TZ)"
git push -q -u origin "$BR"
sleep 8
gh run list -b "$BR" -L 1 --json databaseId,url,status -q '.[0] | "\(.databaseId) \(.status) \(.url)"'
