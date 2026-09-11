"""Hand-rolled invoke workflow resolver with cycle detection.

Synthetic before-code for N0tS0Lucky/piflow#9 (definition-format invoke cycles).
"""

from __future__ import annotations

from collections import deque


class DefinitionError(Exception):
  pass


_ALLOWED_INVOKE_KEYS = frozenset({"id", "type", "workflow"})


def validate_invoke_step(step: dict) -> None:
  unknown = sorted(set(step) - _ALLOWED_INVOKE_KEYS)
  if unknown:
    raise DefinitionError(f"unknown invoke keys: {unknown}")
  if "workflow" not in step:
    raise DefinitionError("invoke step missing required workflow")


def _collect_invoke_targets(steps: list[dict]) -> list[str]:
  out: list[str] = []
  for step in steps:
    stype = step.get("type")
    if stype == "invoke":
      out.append(step["workflow"])
    elif stype == "parallel":
      out.extend(_collect_invoke_targets(step.get("steps", [])))
  return out


def build_invoke_adjacency(workflows: dict[str, dict]) -> dict[str, list[str]]:
  adj: dict[str, list[str]] = {name: [] for name in workflows}
  for name in sorted(workflows):
    targets = sorted(_collect_invoke_targets(workflows[name].get("steps", [])))
    seen: set[str] = set()
    for target in targets:
      if target not in seen:
        seen.add(target)
        adj[name].append(target)
  return adj


def find_cycle_path(adj: dict[str, list[str]], start: str) -> list[str] | None:
  if start not in adj:
    return None
  stack: list[tuple[str, list[str]]] = [(start, [start])]
  while stack:
    node, path = stack.pop()
    for nxt in sorted(adj.get(node, [])):
      if nxt in path:
        idx = path.index(nxt)
        return path[idx:] + [nxt]
      stack.append((nxt, path + [nxt]))
  return None


def detect_invoke_cycles(adj: dict[str, list[str]]) -> list[str] | None:
  for root in sorted(adj):
    cycle = find_cycle_path(adj, root)
    if cycle is not None:
      return cycle
  return None


def _resolve_steps(
  steps: list[dict],
  workflows: dict[str, dict],
  resolved: dict[str, dict],
  source_file: str,
) -> list[dict]:
  out: list[dict] = []
  for step in steps:
    stype = step.get("type")
    if stype == "invoke":
      validate_invoke_step(step)
      target = step["workflow"]
      if target not in workflows:
        sid = step.get("id", "<unknown>")
        raise DefinitionError(
          f"missing workflow '{target}' for step '{sid}' in {source_file}"
        )
      if target not in resolved:
        resolved[target] = _resolve_workflow(target, workflows, resolved, source_file)
      row = dict(step)
      row["resolved_workflow"] = resolved[target]
      out.append(row)
    elif stype == "parallel":
      row = dict(step)
      row["steps"] = _resolve_steps(
        step.get("steps", []), workflows, resolved, source_file
      )
      out.append(row)
    else:
      out.append(dict(step))
  return out


def _resolve_workflow(
  name: str,
  workflows: dict[str, dict],
  resolved: dict[str, dict],
  source_file: str,
) -> dict:
  wf = workflows[name]
  body = dict(wf)
  body["steps"] = _resolve_steps(wf.get("steps", []), workflows, resolved, source_file)
  return body


def resolve_workflows(
  workflows: dict[str, dict],
  *,
  source_file: str = "workflows.yaml",
) -> dict[str, dict]:
  adj = build_invoke_adjacency(workflows)
  cycle = detect_invoke_cycles(adj)
  if cycle is not None:
    raise DefinitionError(
      f"invoke cycle in {source_file}: {' -> '.join(cycle)}"
    )
  resolved: dict[str, dict] = {}
  for name in sorted(workflows):
    resolved[name] = _resolve_workflow(name, workflows, resolved, source_file)
  return resolved
