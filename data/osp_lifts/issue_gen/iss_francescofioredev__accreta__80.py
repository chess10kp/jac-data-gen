"""francescofioredev/accreta#80 — depth-aware lineage without cyclic blow-up."""

from __future__ import annotations

from collections import deque


class LineageStore:
  """Parent/child lineage with cycle-safe depth and closure queries."""

  def __init__(self) -> None:
    self._parent: dict[str, str | None] = {}
    self._children: dict[str, list[str]] = {}

  def add_node(self, node_id: str, parent_id: str | None = None) -> None:
    if node_id in self._parent:
      raise ValueError(f"duplicate node: {node_id}")
    if parent_id is not None and parent_id not in self._parent:
      raise KeyError(parent_id)
    self._parent[node_id] = parent_id
    self._children.setdefault(node_id, [])
    if parent_id is not None:
      self._children.setdefault(parent_id, []).append(node_id)

  def ancestors(self, node_id: str) -> list[str]:
    if node_id not in self._parent:
      raise KeyError(node_id)
  out: list[str] = []
    cur = self._parent.get(node_id)
    seen: set[str] = set()
    while cur is not None:
      if cur in seen:
        break
      seen.add(cur)
      out.append(cur)
      cur = self._parent.get(cur)
    return out

  def descendants(self, node_id: str) -> list[str]:
    if node_id not in self._parent:
      raise KeyError(node_id)
    order: list[str] = []
    q: deque[str] = deque(self._children.get(node_id, []))
    claimed: set[str] = set()
    while q:
      n = q.popleft()
      if n in claimed:
        continue
      claimed.add(n)
      order.append(n)
      for c in self._children.get(n, []):
        if c not in claimed:
          q.append(c)
    return sorted(order)

  def depth_from(self, root_id: str, node_id: str) -> int | None:
    if root_id not in self._parent or node_id not in self._parent:
      raise KeyError(node_id)
    depths: dict[str, int] = {root_id: 0}
    q: deque[str] = deque([root_id])
    claimed: set[str] = {root_id}
    while q:
      n = q.popleft()
      for c in self._children.get(n, []):
        if c in claimed:
          continue
        claimed.add(c)
        depths[c] = depths[n] + 1
        q.append(c)
    return depths.get(node_id)

  def would_cycle(self, parent_id: str, child_id: str) -> bool:
    if parent_id not in self._parent or child_id not in self._parent:
      raise KeyError(parent_id if parent_id not in self._parent else child_id)
    return child_id in self.ancestors(parent_id) or parent_id == child_id
