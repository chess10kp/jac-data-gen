"""stokaro/ptah#1343 — Canonical schema state and migration-order planning.

Hand-rolled parent pointers, children adjacency, dependency lists, reverse
index, deque BFS closure, and Kahn topological sweep for migration sequencing.
"""

from __future__ import annotations

from collections import deque


class SchemaState:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self._objects: set[str] = set()
        self._kinds: dict[str, str] = {}
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._deps: dict[str, list[str]] = {}      # dependent -> upstream refs
        self._rev: dict[str, list[str]] = {}       # referenced -> dependents

    def add_object(self, name: str, kind: str, parent: str | None = None) -> None:
        if name in self._objects:
            raise ValueError("duplicate")
        if parent is not None and parent not in self._objects:
            raise KeyError("unknown parent")
        self._objects.add(name)
        self._kinds[name] = kind
        self._parent[name] = parent
        self._children.setdefault(name, [])
        self._deps.setdefault(name, [])
        self._rev.setdefault(name, [])
        if parent is not None:
            self._children.setdefault(parent, []).append(name)

    def add_dependency(self, dependent: str, referenced: str) -> None:
        if dependent not in self._objects or referenced not in self._objects:
            raise KeyError("unknown object")
        self._deps[dependent].append(referenced)
        self._rev[referenced].append(dependent)

    def parent_chain(self, name: str) -> list[str]:
        if name not in self._objects:
            return []
        out: list[str] = []
        seen: set[str] = set()
        par = self._parent.get(name)
        while par is not None:
            if par in seen:
                break
            seen.add(par)
            out.append(par)
            par = self._parent.get(par)
        return out

    def dependencies_of(self, name: str) -> list[str]:
        if name not in self._objects:
            return []
        return sorted(self._deps.get(name, []))

    def transitive_dependencies(self, name: str) -> list[str]:
        if name not in self._objects:
            return []
        seen: set[str] = {name}
        queue: deque[str] = deque(self._deps.get(name, []))
        hits: list[str] = []
        while queue:
            cur = queue.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            hits.append(cur)
            for nxt in self._deps.get(cur, []):
                if nxt not in seen:
                    queue.append(nxt)
        return sorted(hits)

    def migration_order(self) -> list[str] | None:
        indeg: dict[str, int] = {
            n: len(self._deps.get(n, [])) for n in self._objects
        }
        placed: set[str] = set()
        order: list[str] = []
        while len(placed) < len(self._objects):
            ready = sorted(
                n for n in self._objects if n not in placed and indeg[n] == 0
            )
            if not ready:
                return None
            pick = ready[0]
            placed.add(pick)
            order.append(pick)
            for child in self._rev.get(pick, []):
                indeg[child] -= 1
        return order
