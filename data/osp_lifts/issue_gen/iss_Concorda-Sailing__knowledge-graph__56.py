"""Concorda-Sailing/knowledge-graph#56 — dossier outbound dependency reach."""

from collections import deque


class DossierGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._out: dict[str, list[str]] = {}


def load_dossiers(nodes: list[str], edges: list[tuple[str, str]]) -> DossierGraph:
    g = DossierGraph()
    for n in nodes:
        g._nodes.add(n)
        g._out.setdefault(n, [])
    for src, dst in edges:
        if src in g._nodes and dst in g._nodes:
            g._out.setdefault(src, []).append(dst)
    return g


def outbound_reach(store: DossierGraph, node: str) -> list[str]:
    if node not in store._nodes:
        return []
    seen: set[str] = {node}
    queue: deque[str] = deque([node])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for nxt in store._out.get(cur, []):
            out.add(nxt)
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(out)
