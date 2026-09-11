"""INRIA/spoon#6802 — Wildcard type erasure reference walk with cycle guard.

Hand-rolled bound-reference adjacency and recursive erasure resolution that
must terminate when executable lookup re-enters the same wildcard parameter.
"""

from __future__ import annotations


class TypeGraph:
    def __init__(self) -> None:
        self.types: set[str] = set()
        self.bound_ref: dict[str, str] = {}
        self.erased: dict[str, str] = {}


def load_type_graph(
    types: list[str],
    bound_refs: list[tuple[str, str]],
    erased: list[tuple[str, str]],
) -> TypeGraph:
    g = TypeGraph()
    for tid in types:
        g.types.add(tid)
    for src, dst in bound_refs:
        if src in g.types and dst in g.types:
            g.bound_ref[src] = dst
    for tid, name in erased:
        if tid in g.types:
            g.erased[tid] = name
    return g


def _resolve_bound(g: TypeGraph, tid: str, visiting: set[str]) -> str:
    cur = tid
    while cur in g.bound_ref:
        if cur in visiting:
            return g.erased.get(cur, "Object")
        visiting.add(cur)
        cur = g.bound_ref[cur]
    return g.erased.get(cur, "Object")


def erasure_chain(g: TypeGraph, type_id: str) -> list[str]:
    if type_id not in g.types:
        return []
    chain: list[str] = [type_id]
    visiting: set[str] = {type_id}
    cur = type_id
    while cur in g.bound_ref:
        nxt = g.bound_ref[cur]
        if nxt in visiting:
            break
        visiting.add(nxt)
        chain.append(nxt)
        cur = nxt
    return chain


def erasure_of(g: TypeGraph, type_id: str) -> str:
    if type_id not in g.types:
        return "Object"
    return _resolve_bound(g, type_id, set())
