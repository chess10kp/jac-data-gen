"""linkml/linkml-term-validator#58 — OAK reachable_from closure scope validation."""
from __future__ import annotations

from collections import deque


class Term:
    def __init__(self, term_id: str) -> None:
        self.term_id = term_id


class OntologyStore:
    def __init__(self) -> None:
        self.terms_by_id: dict[str, Term] = {}
        self._is_a_children: dict[str, list[str]] = {}
        self._is_a_parents: dict[str, list[str]] = {}
        self._part_of_parts: dict[str, list[str]] = {}
        self._part_of_wholes: dict[str, list[str]] = {}

    def add_term(self, term_id: str) -> Term:
        t = Term(term_id)
        self.terms_by_id[term_id] = t
        return t

    def link_is_a(self, child_id: str, parent_id: str) -> None:
        if child_id not in self.terms_by_id or parent_id not in self.terms_by_id:
            return
        self._is_a_children.setdefault(parent_id, []).append(child_id)
        self._is_a_parents.setdefault(child_id, []).append(parent_id)

    def link_part_of(self, part_id: str, whole_id: str) -> None:
        if part_id not in self.terms_by_id or whole_id not in self.terms_by_id:
            return
        self._part_of_parts.setdefault(whole_id, []).append(part_id)
        self._part_of_wholes.setdefault(part_id, []).append(whole_id)


def _closure_bfs(
    start_id: str,
    neighbors,
    claims: dict[str, bool],
    out: list[str],
    prefix_filter: str | None = None,
) -> None:
    queue: deque[str] = deque([start_id])
    while queue:
        current = queue.popleft()
        if current in claims:
            continue
        claims[current] = True
        if prefix_filter is None or prefix_filter == "" or current.startswith(prefix_filter):
            out.append(current)
        for nxt in neighbors(current):
            if nxt not in claims:
                queue.append(nxt)


def descendants(
    store: OntologyStore,
    term_id: str,
    include_part_of: bool = False,
    prefix_filter: str = "",
) -> list[str]:
    if term_id not in store.terms_by_id:
        return []

    claims: dict[str, bool] = {}
    out: list[str] = []

    def neighbors(node_id: str) -> list[str]:
        nbrs = list(store._is_a_children.get(node_id, []))
        if include_part_of:
            nbrs.extend(store._part_of_parts.get(node_id, []))
        return nbrs

    _closure_bfs(term_id, neighbors, claims, out, prefix_filter)
    return sorted(out)


def ancestors(
    store: OntologyStore,
    term_id: str,
    include_part_of: bool = False,
) -> list[str]:
    if term_id not in store.terms_by_id:
        return []

    claims: dict[str, bool] = {}
    out: list[str] = []

    def neighbors(node_id: str) -> list[str]:
        nbrs = list(store._is_a_parents.get(node_id, []))
        if include_part_of:
            nbrs.extend(store._part_of_wholes.get(node_id, []))
        return nbrs

    _closure_bfs(term_id, neighbors, claims, out, prefix_filter=None)
    return sorted(out)
