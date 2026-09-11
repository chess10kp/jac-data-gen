"""markmhendrickson/neotoma#1969 — KNOWS edges + warm-path find_paths to company/fund targets.

Hand-rolled adjacency dicts for KNOWS, affiliation maps for works_at / invested_in,
and an explicit stack loop for path enumeration with path-local cycle guards.
"""

from __future__ import annotations

MAX_PATH_DEPTH = 4


class GraphStore:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self.stamp = 1
        self._knows: dict[str, list[str]] = {}
        self._works_at: dict[str, str] = {}
        self._invested_in: dict[str, list[str]] = {}
        self._kinds: dict[str, str] = {}
        self._nodes: set[str] = set()


def load_graph(
    entities: list[tuple[str, str]],
    knows: list[tuple[str, str]],
    works_at: list[tuple[str, str]],
    invested_in: list[tuple[str, str]],
) -> GraphStore:
    g = GraphStore()
    for eid, kind in entities:
        g._nodes.add(eid)
        g._kinds[eid] = kind
        if kind == "contact":
            g._knows.setdefault(eid, [])
    for a, b in knows:
        if (
            a in g._nodes
            and b in g._nodes
            and g._kinds.get(a) == "contact"
            and g._kinds.get(b) == "contact"
        ):
            if b not in g._knows.setdefault(a, []):
                g._knows[a].append(b)
    for cid, coid in works_at:
        if (
            cid in g._nodes
            and coid in g._nodes
            and g._kinds.get(cid) == "contact"
            and g._kinds.get(coid) == "company"
        ):
            g._works_at[cid] = coid
    for fid, coid in invested_in:
        if (
            fid in g._nodes
            and coid in g._nodes
            and g._kinds.get(fid) == "fund"
            and g._kinds.get(coid) == "company"
        ):
            g._invested_in.setdefault(fid, [])
            if coid not in g._invested_in[fid]:
                g._invested_in[fid].append(coid)
    return g


def knows_of(g: GraphStore, contact_id: str) -> list[str]:
    if contact_id not in g._nodes or g._kinds.get(contact_id) != "contact":
        return []
    return sorted(g._knows.get(contact_id, []))


def _contacts_at_target(g: GraphStore, target_id: str) -> list[str]:
    kind = g._kinds.get(target_id)
    if kind == "company":
        return sorted(c for c, co in g._works_at.items() if co == target_id)
    if kind == "fund":
        hits: set[str] = set()
        for co in g._invested_in.get(target_id, []):
            for c, w in g._works_at.items():
                if w == co:
                    hits.add(c)
        return sorted(hits)
    return []


def find_paths(
    g: GraphStore,
    start: str,
    target_id: str,
    max_depth: int = MAX_PATH_DEPTH,
) -> list[list[str]]:
    if start not in g._nodes or g._kinds.get(start) != "contact":
        return []
    targets = _contacts_at_target(g, target_id)
    if not targets:
        return []
    target_set = set(targets)
    knows = g._knows
    results: list[list[str]] = []
    stack: list[tuple[str, list[str], int]] = [(start, [start], 0)]
    while stack:
        cur, path, hops = stack.pop()
        if cur in target_set:
            results.append(list(path))
        if hops >= max_depth:
            continue
        for nb in sorted(knows.get(cur, []), reverse=True):
            if nb in path:
                continue
            stack.append((nb, path + [nb], hops + 1))
    return sorted(results)
