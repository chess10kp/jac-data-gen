#!/usr/bin/env bash
# py2jac_dogfood.py — run `jac tool py2jac` over every Python sample in the
# MultiPL-T corpus (nuprl/stack-dedup-python-testgen-starcoder-filter-v2, cached
# in ~/.cache/huggingface) and accumulate failures.
#
# Usage (from jac_llm_data, or anywhere):
#   ~/repos/jac_llm_data/.venv/bin/python ~/repos/jac_llm_data/scripts/py2jac_dogfood.py \
#       [--workers 12] [--limit N] [--timeout 30] [--jac PATH] [--out-dir DIR] \
#       [--with-tests] [--offset N] [--fresh]
#
# Defaults:
#   --jac     /home/jac/repos/jaseci/.venv/bin/jac   (editable upstream checkout)
#   --out-dir <repo>/archive/2026-09/scratch/py2jac_dogfood
#
# Outputs in --out-dir:
#   failures.jsonl      one record per FAILED sample: id, entrypoint, coverage,
#                       rc, error (tail of stderr/stdout), content (the python)
#   done.jsonl          one record per finished sample (pass|fail) — resume ledger
#   run.log             progress lines
#   failures_summary.md written at end: totals + top error signatures
#
# Resume: rerunning skips ids already present in done.jsonl. Use --fresh to wipe
# the ledger first (also clears failures.jsonl).

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$REPO_ROOT/.venv/bin/python" "$REPO_ROOT/scripts/py2jac_dogfood.py" "$@"
