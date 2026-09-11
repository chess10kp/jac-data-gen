"""TheAlgorithms/Python#15071 — Kahn topo: pop(0) queue + sparse vertex IndexError."""

from __future__ import annotations


class TopoGraph:
    def __init__(self) -> None:
        self.adj: dict[int, list[int]] = {}


def load_graph(edges: list[tuple[int, int]]) -> TopoGraph:
    g = TopoGraph()
    for u, v in edges:
        g.adj.setdefault(u, []).append(v)
        g.adj.setdefault(v, g.adj.get(v, []))
    return g


def topological_sort(g: TopoGraph) -> list[int]:
    verts = sorted(g.adj.keys())
    # BUG: dense list indexed by vertex id breaks on sparse ids (0, 5, 10)
    indeg = [0] * len(verts)
    for u in verts:
        for v in g.adj[u]:
            indeg[v] += 1  # IndexError when v=10 but len(indeg)==3
    q = [u for u in verts if indeg[u] == 0]
    out: list[int] = []
    while q:
        u = q.pop(0)  # inefficient pop(0)
        out.append(u)
        for v in g.adj[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return out if len(out) == len(verts) else []


def reachable_from(g: TopoGraph, start: int) -> list[int]:
    if start not in g.adj:
        return []
    seen: set[int] = set()
    stack = [start]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.adj.get(cur, []):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(seen)
