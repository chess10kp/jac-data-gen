#!/usr/bin/env bash
# Pinned deploy profile for the Jac coding agent: the exact prompt, tools and
# tool-result formats that SFT trajectories are recorded with and that the
# fine-tuned model is deployed with. Run it from the project to work on:
#
#   deploy/jacpi.sh --model zai/glm-5.3-flash -p "add a /health walker"
#
# What it pins:
#   - system prompt = deploy/SYSTEM.md (replaces pi's default prompt; pi only
#     appends "Current working directory: <cwd>")
#   - tools = read, bash, write, jac_ast_search, jac_ast_edit (no edit, no MCP)
#   - no skills, prompt templates, context files (AGENTS.md/CLAUDE.md),
#     discovered extensions or project-local .pi/ resources
#   - an isolated agent dir (default ~/.pi/jacpi-deploy) that must not hold
#     SYSTEM.md / APPEND_SYSTEM.md / mcp.json; auth.json and models.json are
#     linked from ~/.pi/agent so providers keep working
# Every session records the final prompt + tool schemas as a
# `jac-harness-snapshot` entry in its JSONL (see README).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$(dirname "$HERE")"
AGENT_DIR="${JACPI_AGENT_DIR:-$HOME/.pi/jacpi-deploy}"
SOURCE_AGENT_DIR="${JACPI_SOURCE_AGENT_DIR:-$HOME/.pi/agent}"
TOOLS="read,bash,write,jac_ast_search,jac_ast_edit"

mkdir -p "$AGENT_DIR"
for f in auth.json models.json; do
  if [[ ! -e "$AGENT_DIR/$f" && -e "$SOURCE_AGENT_DIR/$f" ]]; then
    ln -s "$SOURCE_AGENT_DIR/$f" "$AGENT_DIR/$f"
  fi
done
for f in SYSTEM.md APPEND_SYSTEM.md mcp.json; do
  if [[ -e "$AGENT_DIR/$f" ]]; then
    echo "jacpi: $AGENT_DIR/$f would change the pinned prompt or tools; remove it." >&2
    exit 2
  fi
done
if [[ -e "$AGENT_DIR/settings.json" ]] && grep -q '"packages"' "$AGENT_DIR/settings.json"; then
  echo "jacpi: $AGENT_DIR/settings.json lists packages; the deploy profile loads none. Remove them." >&2
  exit 2
fi

exec env PI_CODING_AGENT_DIR="$AGENT_DIR" pi \
  --offline \
  --no-extensions -e "$PKG/extensions/jac-ast-edit.ts" \
  --no-skills --no-prompt-templates --no-context-files --no-approve \
  --system-prompt "$HERE/SYSTEM.md" \
  --tools "$TOOLS" \
  "$@"
