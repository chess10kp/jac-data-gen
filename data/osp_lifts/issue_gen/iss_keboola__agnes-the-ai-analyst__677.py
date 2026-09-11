"""keboola/agnes-the-ai-analyst#677 — cross-document entity linking graph.

Collections ontology layer: documents mention entities; co-mention within a
document materializes entity-entity links for bounded relational traversal.
"""

from __future__ import annotations

from collections import deque


class EntityGraph:
    """In-memory entity-link index; fresh instance per test."""

    def __init__(self) -> None:
        self._doc_entities: dict[str, list[str]] = {}
        self._known: set[str] = set()
        self._adj: dict[str, list[str]] = {}

    def mention(self, doc: str, entity: str) -> None:
        self._known.add(entity)
        bucket = self._doc_entities.setdefault(doc, [])
        if entity not in bucket:
            bucket.append(entity)
        self._adj.setdefault(entity, [])
        for other in bucket:
            if other == entity:
                continue
            if other not in self._adj[entity]:
                self._adj[entity].append(other)
            self._adj.setdefault(other, [])
            if entity not in self._adj[other]:
                self._adj[other].append(entity)

    def linked_entities(self, entity: str, max_hops: int) -> list[str]:
        if entity not in self._known:
            return []
        seen: set[str] = {entity}
        frontier: list[str] = [entity]
        hits: list[str] = []
        for _ in range(max_hops):
            nxt: list[str] = []
            for cur in frontier:
                for nb in self._adj.get(cur, []):
                    if nb in seen:
                        continue
                    seen.add(nb)
                    hits.append(nb)
                    nxt.append(nb)
            frontier = nxt
            if not frontier:
                break
        return sorted(hits)

    def bridge(self, a: str, b: str) -> list[str] | None:
        if a not in self._known or b not in self._known:
            return None
        if a == b:
            return [a]
        parent: dict[str, str] = {}
        claimed: set[str] = {a}
        queue: deque[str] = deque([a])
        while queue:
            cur = queue.popleft()
            if cur == b:
                path: list[str] = []
                node: str | None = b
                while node is not None:
                    path.append(node)
                    node = parent.get(node) if node != a else None
                return list(reversed(path))
            for nb in self._adj.get(cur, []):
                if nb in claimed:
                    continue
                claimed.add(nb)
                parent[nb] = cur
                queue.append(nb)
        return None
