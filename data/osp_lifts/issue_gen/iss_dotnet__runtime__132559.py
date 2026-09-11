"""dotnet/runtime#132559 — Mono AOT generic parent chains and build-target dependency closure.

Models recursive generic type parent links (JIT.Generics_ro type-load failures) and
MSBuild-style aot-compile target prerequisites as hand-rolled adjacency graphs.
"""

from __future__ import annotations

from collections import deque


class AotGenericGraph:
  def __init__(self) -> None:
    self.types: set[str] = set()
    self.parent: dict[str, str] = {}
    self.steps: set[str] = set()
    self.deps: dict[str, list[str]] = {}


def load_aot_generic_graph(
  types: list[tuple[str, str]],
  steps: list[str],
  step_deps: list[tuple[str, str]],
) -> AotGenericGraph:
  g = AotGenericGraph()
  for name, base in types:
    g.types.add(name)
    g.parent[name] = base if base else ""
  for step in steps:
    g.steps.add(step)
    g.deps.setdefault(step, [])
  for consumer, prereq in step_deps:
    if consumer in g.steps and prereq in g.steps:
      g.deps.setdefault(consumer, []).append(prereq)
  return g


def transitive_bases(g: AotGenericGraph, type_name: str) -> list[str]:
  if type_name not in g.types:
    return []
  seen: set[str] = set()
  queue: deque[str] = deque()
  base = g.parent.get(type_name, "")
  if base:
    queue.append(base)
  while queue:
    cur = queue.popleft()
    if cur in seen:
      continue
    seen.add(cur)
    nxt = g.parent.get(cur, "")
    if nxt:
      queue.append(nxt)
  return sorted(seen)


def recursive_generic_types(g: AotGenericGraph) -> list[str]:
  cycle_nodes: set[str] = set()
  state: dict[str, int] = {t: 0 for t in g.types}

  def dfs(u: str) -> None:
    state[u] = 1
    base = g.parent.get(u, "")
    if base and base in g.types:
      if state[base] == 1:
        cur = u
        cycle_nodes.add(base)
        while cur != base:
          cycle_nodes.add(cur)
          cur = g.parent.get(cur, "")
          if not cur:
            break
      elif state[base] == 0:
        dfs(base)
    state[u] = 2

  for t in sorted(g.types):
    if state[t] == 0:
      dfs(t)
  return sorted(cycle_nodes)


def transitive_build_prereqs(g: AotGenericGraph, step: str) -> list[str]:
  if step not in g.steps:
    return []
  seen: set[str] = {step}
  found: set[str] = set()
  queue: deque[str] = deque(g.deps.get(step, []))
  while queue:
    cur = queue.popleft()
    if cur in seen:
      continue
    seen.add(cur)
    found.add(cur)
    queue.extend(g.deps.get(cur, []))
  return sorted(found)


def build_prereq_paths(
  g: AotGenericGraph,
  source: str,
  target: str,
  *,
  max_depth: int = 12,
) -> list[list[str]]:
  if source not in g.steps or target not in g.steps:
    return []
  out: list[list[str]] = []
  stack: list[tuple[str, list[str]]] = [(source, [source])]
  while stack:
    node, trail = stack.pop()
    if node == target:
      out.append(trail)
      continue
    if len(trail) >= max_depth:
      continue
    for nxt in g.deps.get(node, []):
      if nxt not in trail:
        stack.append((nxt, trail + [nxt]))
  return sorted(out)
