"""johnkim9524-collab/kaios_enterprise_repo#1272 — Governed executable dependency closure.

Portal runtime modules reference each other; trust validation must compute the
transitive dependency closure from governed roots using an adjacency dict and
deque frontier walk with cycle-safe visited tracking.
"""

from __future__ import annotations

from collections import deque


class TrustGraph:
    def __init__(self) -> None:
        self.modules: set[str] = set()
        self.requires: dict[str, list[str]] = {}


def load_trust_graph(
    modules: list[str],
    edges: list[tuple[str, str]],
) -> TrustGraph:
    g = TrustGraph()
    for mod in modules:
        g.modules.add(mod)
        g.requires.setdefault(mod, [])
    for src, dst in edges:
        if src in g.modules and dst in g.modules:
            g.requires.setdefault(src, []).append(dst)
            g.requires.setdefault(dst, g.requires.get(dst, []))
    return g


def dependency_closure(g: TrustGraph, roots: list[str]) -> list[str]:
    seen: set[str] = set()
    q: deque[str] = deque()
    for r in roots:
        if r in g.modules and r not in seen:
            seen.add(r)
            q.append(r)
    while q:
        cur = q.popleft()
        for nxt in g.requires.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                q.append(nxt)
    return sorted(seen)


def rejects_escape(g: TrustGraph, roots: list[str], candidate: str) -> bool:
    closure = set(dependency_closure(g, roots))
    return candidate not in closure
