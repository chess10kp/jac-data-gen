"""EffortlessMetrics/perl-lsp-swarm#8143 — string relations → source-anchored typed edges."""

from __future__ import annotations

from collections import deque


class SymbolStore:
    # Legacy hand-rolled projection: string keys + adjacency buckets.
    def __init__(self) -> None:
        self.anchors: dict[str, str] = {}
        self.parents: dict[str, list[tuple[int, str]]] = {}
        self.adj: dict[str, list[tuple[str, str]]] = {}
        self.nodes: set[str] = set()


def load_symbols(
    entities: list[tuple[str, str]],
    parent_lists: list[tuple[str, list[str]]],
    uses: list[tuple[str, str]],
    tests: list[tuple[str, str]],
) -> SymbolStore:
    g = SymbolStore()
    for sid, anchor in entities:
        g.nodes.add(sid)
        g.anchors[sid] = anchor
        g.adj.setdefault(sid, [])
        g.parents.setdefault(sid, [])
    for child, plist in parent_lists:
        if child not in g.nodes:
            continue
        for i, par in enumerate(plist):
            if par in g.nodes:
                g.parents[child].append((i + 1, par))
                g.adj.setdefault(child, []).append(("Inherits", par))
    for src, dst in uses:
        if src in g.nodes and dst in g.nodes:
            g.adj.setdefault(src, []).append(("Uses", dst))
    for src, dst in tests:
        if src in g.nodes and dst in g.nodes:
            g.adj.setdefault(src, []).append(("Tests", dst))
    return g


def ordered_parents(store: SymbolStore, symbol: str) -> list[str]:
    if symbol not in store.nodes:
        return []
    pairs = sorted(store.parents.get(symbol, []))
    return [p for _ord, p in pairs]


def typed_refs(store: SymbolStore, src: str, kind: str) -> list[str]:
    if src not in store.nodes:
        return []
    hits = [tgt for k, tgt in store.adj.get(src, []) if k == kind]
    return sorted(hits)


def ref_closure(store: SymbolStore, start: str) -> list[str]:
    if start not in store.nodes:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for _kind, tgt in store.adj.get(cur, []):
            if tgt not in seen:
                q.append(tgt)
    return sorted(seen)


def ancestor_chain(store: SymbolStore, symbol: str) -> list[str]:
    if symbol not in store.nodes:
        return []
    chain = [symbol]
    claimed = {symbol}
    cur = symbol
    while True:
        plist = sorted(store.parents.get(cur, []))
        nxt = None
        for _ord, par in plist:
            if par not in claimed:
                nxt = par
                break
        if nxt is None:
            break
        claimed.add(nxt)
        chain.append(nxt)
        cur = nxt
    return chain
