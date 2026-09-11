"""msqd/harp#803 — perf: optimize topological sort to O(N+E) complexity."""

from __future__ import annotations

from collections import deque


class TopoGraph:
  def __init__(self) -> None:
    self._adj: dict[int, list[int]] = {}


def load_graph(edges: list[tuple[int, int]]) -> TopoGraph:
  g = TopoGraph()
  for u, v in edges:
    g._adj.setdefault(u, []).append(v)
    g._adj.setdefault(v, g._adj.get(v, []))
  return g


def topological_sort(g: TopoGraph) -> list[int]:
  indeg: dict[int, int] = {v: 0 for v in g._adj}
  for u in g._adj:
    for v in g._adj[u]:
      indeg[v] += 1
  q: deque[int] = deque(sorted([v for v, d in indeg.items() if d == 0]))
  out: list[int] = []
  while q:
    u = q.popleft()
    out.append(u)
    for v in g._adj.get(u, []):
      indeg[v] -= 1
      if indeg[v] == 0:
        q.append(v)
  return out if len(out) == len(indeg) else []


def reachable_from(g: TopoGraph, start: int) -> list[int]:
  if start not in g._adj:
    return []
  seen: set[int] = set()
  stack = [start]
  while stack:
    cur = stack.pop()
    if cur in seen:
      continue
    seen.add(cur)
    for nxt in g._adj.get(cur, []):
      if nxt not in seen:
        stack.append(nxt)
  return sorted(seen)
