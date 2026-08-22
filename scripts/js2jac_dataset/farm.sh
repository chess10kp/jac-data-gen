#!/usr/bin/env bash
# ENTRYPOINT — FARM burndown: Mongo/Beanie app models -> CRUD walker corpus.
#
# Stages: discover new model repos -> prep archetypes -> composer -> behavioral
# guard -> master append. Every stage idempotent/resume-safe; safe to re-run.
#
# Usage:
#   ./farm.sh                       # full run: discover 200 + prep refresh + grind
#   ./farm.sh full 500              # same, discovery limit 500
#   ./farm.sh grind 500 500         # grind chunks only, from offset 500
#   ./farm.sh to 3000               # loop full runs until master hits 3000 records
#   ./farm.sh handler 30            # handler-mode corpus (real FastAPI code context)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

CMD="${1:-full}"
shift || true

case "$CMD" in
  full)    exec bash "$HERE/full_run.sh" "$@" ;;
  grind)   exec bash "$HERE/grind.sh" "$@" ;;
  to)      exec bash "$HERE/to_target.sh" "$@" ;;
  handler) exec bash "$HERE/handler_run.sh" "$@" ;;
  *) sed -n '2,11p' "$0"; echo "unknown command: $CMD (want full|grind|to|handler)" >&2; exit 2 ;;
esac
