"""rustpunk/clinker#1058 — Pipeline composition lineage node enumeration."""

from __future__ import annotations


class PipelineStore:
    # Top-level DAG plus nested composition-body parent links.
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._in_body: set[str] = set()


def load_pipeline(
    nodes: list[str],
    edges: list[tuple[str, str]],
    body_nodes: list[str] | None = None,
) -> PipelineStore:
    ps = PipelineStore()
    for n in nodes:
        ps._nodes.add(n)
        ps._parent[n] = None
        ps._children.setdefault(n, [])
    for src, dst in edges:
        if src in ps._nodes and dst in ps._nodes:
            ps._parent[dst] = src
            ps._children.setdefault(src, []).append(dst)
    for bn in body_nodes or []:
        if bn in ps._nodes:
            ps._in_body.add(bn)
    return ps


def _walk_up(store: PipelineStore, node: str, acc: list[str], seen: set[str]) -> None:
    parent = store._parent.get(node)
    while parent is not None:
        if parent in seen:
            break
        seen.add(parent)
        acc.append(parent)
        parent = store._parent.get(parent)


def all_lineage_nodes(store: PipelineStore, start: str) -> list[str]:
    if start not in store._nodes:
        return []
    out: set[str] = {start}
    stack: list[str] = [start]
    seen: set[str] = {start}
    while stack:
        cur = stack.pop()
        for ch in store._children.get(cur, []):
            if ch not in seen:
                seen.add(ch)
                out.add(ch)
                stack.append(ch)
    extra: list[str] = []
    _walk_up(store, start, extra, set(seen))
    out.update(extra)
    return sorted(out)


def composition_body_nodes(store: PipelineStore) -> list[str]:
    return sorted(store._in_body)


def missing_binding(store: PipelineStore, node: str) -> bool:
    if node not in store._nodes:
        return True
    if node in store._in_body and store._parent.get(node) is None:
        return True
    return False
