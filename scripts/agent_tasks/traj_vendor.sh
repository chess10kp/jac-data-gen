#!/usr/bin/env bash
# Vendor the pinned pi-jac-ast-edit deploy harness into vendor/pi-jac-ast-edit/
# (its changes are uncommitted upstream, so CI gets an exact copy). Writes
# VENDORED.json with the source HEAD, dirty flag and a content hash of the
# files that define the prompt / tools (SYSTEM.md, jacpi.sh, extension, engine).
# Usage: scripts/agent_tasks/traj_vendor.sh [SRC=~/repos/pi-jac-ast-edit]
set -euo pipefail
SRC="${1:-$HOME/repos/pi-jac-ast-edit}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DST="$REPO/vendor/pi-jac-ast-edit"
mkdir -p "$DST"
rsync -a --delete \
  --exclude .git --exclude .venv --exclude node_modules --exclude __pycache__ \
  --exclude '*.egg-info' --exclude .pytest_cache --exclude '*.so' --exclude native/ \
  --exclude .jac --exclude __jac_gen__ \
  "$SRC/" "$DST/"
head=$(git -C "$SRC" rev-parse HEAD 2>/dev/null || echo unknown)
dirty=$(git -C "$SRC" status --porcelain 2>/dev/null | wc -l)
pin=$(cd "$DST" && cat deploy/SYSTEM.md deploy/jacpi.sh extensions/jac-ast-edit.ts python/jac_ast_edit.py \
      python/edit_view.py python/jac_check.py | sha256sum | cut -c1-16)
printf '{"source": "%s", "head": "%s", "dirty_files": %s, "pin_hash": "%s", "vendored_at": "%s"}\n' \
  "$SRC" "$head" "$dirty" "$pin" "$(date -u +%FT%TZ)" > "$DST/VENDORED.json"
cat "$DST/VENDORED.json"
