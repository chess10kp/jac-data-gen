#!/usr/bin/env bash
# ENTRYPOINT — js2jac corpus grind: React/TSX sources -> idiomatic Jac dataset.
#
# Full pipeline per chunk: prep -> floor-gate -> composer -> guard -> master
# append -> repair pass. Resume-safe at every stage; re-run freely.
#
# Usage:
#   ./js2jac.sh                          # grind from offset 0, 20 repos/chunk
#   ./js2jac.sh grind 200 40 --faithful  # grind from offset 200, faithful mode
#   ./js2jac.sh chunk 200 40             # single chunk (debug a slice)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

CMD="${1:-grind}"
shift || true

case "$CMD" in
  grind) exec bash pipeline/grind.sh "$@" ;;
  chunk) exec bash pipeline/chunk.sh "$@" ;;
  *) sed -n '2,10p' "$0"; echo "unknown command: $CMD (want grind|chunk)" >&2; exit 2 ;;
esac
