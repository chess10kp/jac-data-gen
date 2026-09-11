"""backspring-labs/squad-ops#578

Plan DAG cycle detection and depends_on execution ordering.
Hand-rolled adjacency + Kahn topological sort (pre-OSP).
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Optional, Set


class CycleError(ValueError):
  """Raised when depends_on graph contains a cycle."""


class PlanStore:
  """Mutable plan graph keyed by task id."""

  def __init__(self) -> None:
    self._nodes: Set[str] = set()
    self._deps: Dict[str, List[str]] = {}
    self._rev: Dict[str, List[str]] = {}

  def add_task(self, task_id: str) -> None:
    self._nodes.add(task_id)
    self._deps.setdefault(task_id, [])
    self._rev.setdefault(task_id, [])

  def add_depends_on(self, task_id: str, depends_on: str) -> None:
    if task_id not in self._nodes or depends_on not in self._nodes:
      raise KeyError("unknown task id")
    self._deps[task_id].append(depends_on)
    self._rev[depends_on].append(task_id)

  def find_cycle(self) -> List[str]:
    """Return one cycle as id list, or [] if acyclic."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color: Dict[str, int] = {n: WHITE for n in self._nodes}
    parent: Dict[str, Optional[str]] = {n: None for n in self._nodes}
    stack: List[str] = []

    def dfs(u: str) -> List[str]:
      color[u] = GRAY
      stack.append(u)
      for v in self._deps.get(u, []):
        if color[v] == WHITE:
          parent[v] = u
          found = dfs(v)
          if found:
            return found
        elif color[v] == GRAY:
          # back-edge: extract cycle from stack
          if v in stack:
            i = stack.index(v)
            return stack[i:] + [v]
          return [v, u, v]
      stack.pop()
      color[u] = BLACK
      return []

    for n in sorted(self._nodes):
      if color[n] == WHITE:
        cyc = dfs(n)
        if cyc:
          return cyc
    return []

  def execution_order(self) -> List[str]:
    """Topological order respecting depends_on (deps before dependents)."""
    cyc = self.find_cycle()
    if cyc:
      raise CycleError("cycle in plan dag")
    indeg: Dict[str, int] = {n: 0 for n in self._nodes}
    for t, preds in self._deps.items():
      for p in preds:
        indeg[t] += 1
    q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
    out: List[str] = []
    while q:
      u = q.popleft()
      out.append(u)
      for v in sorted(self._rev.get(u, [])):
        indeg[v] -= 1
        if indeg[v] == 0:
          q.append(v)
    if len(out) != len(self._nodes):
      raise CycleError("cycle in plan dag")
    return out

  def reachable_from(self, start: str) -> List[str]:
    """DFS closure along depends_on reverse edges (downstream tasks)."""
    if start not in self._nodes:
      return []
    seen: Set[str] = set()
    out: List[str] = []
    stack: List[str] = [start]
    while stack:
      u = stack.pop()
      if u in seen:
        continue
      seen.add(u)
      out.append(u)
      for v in self._rev.get(u, []):
        if v not in seen:
          stack.append(v)
    return sorted(out)
