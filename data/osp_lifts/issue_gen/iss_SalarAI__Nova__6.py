"""SalarAI/Nova#6 — Implement Graph and BFS/DFS."""

from __future__ import annotations

from collections import deque


class GraphError(ValueError):
    pass


class Graph:
  def __init__(self) -> None:
    self._adj: dict[str, list[str]] = {}
    self._labels: dict[str, str] = {}


def add_node(g: Graph, node_id: str, label: str = "") -> None:
  if node_id not in g._labels:
    g._labels[node_id] = label
    g._adj[node_id] = []


def add_edge(g: Graph, src: str, dst: str) -> None:
  if src not in g._labels or dst not in g._labels:
    raise GraphError("unknown node")
  g._adj[src].append(dst)


def bfs_order(g: Graph, start: str) -> list[str]:
  if start not in g._labels:
    return []
  seen: set[str] = set()
  q: deque[str] = deque([start])
  order: list[str] = []
  while q:
    cur = q.popleft()
    if cur in seen:
      continue
    seen.add(cur)
    order.append(cur)
    for nxt in g._adj.get(cur, []):
      if nxt not in seen:
        q.append(nxt)
  return sorted(order)


def dfs_order(g: Graph, start: str) -> list[str]:
  if start not in g._labels:
    return []
  seen: set[str] = set()
  stack: list[str] = [start]
  order: list[str] = []
  while stack:
    cur = stack.pop()
    if cur in seen:
      continue
    seen.add(cur)
    order.append(cur)
    for nxt in reversed(g._adj.get(cur, [])):
      if nxt not in seen:
        stack.append(nxt)
  return sorted(order)


def is_reachable(g: Graph, start: str, target: str) -> bool:
  return target in bfs_order(g, start)


def has_cycle(g: Graph) -> bool:
  color: dict[str, int] = {n: 0 for n in g._labels}
  def dfs(u: str) -> bool:
    color[u] = 1
    for v in g._adj.get(u, []):
      if color[v] == 1:
        return True
      if color[v] == 0 and dfs(v):
        return True
    color[u] = 2
    return False
  return any(dfs(n) for n in sorted(g._labels) if color[n] == 0)
