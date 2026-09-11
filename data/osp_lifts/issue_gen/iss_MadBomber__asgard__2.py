"""MadBomber/asgard#2 — infer parallel execution waves from dependency graph."""
from collections import deque

class DagStore:
    def __init__(self) -> None:
        self.up: dict[str, list[str]] = {}
        self.down: dict[str, list[str]] = {}
        self.nodes: set[str] = set()

def load_dag(tasks: list[str], edges: list[tuple[str, str]]) -> DagStore:
    g = DagStore()
    for t in tasks:
        g.nodes.add(t); g.up.setdefault(t, []); g.down.setdefault(t, [])
    for a, b in edges:
        if a in g.nodes and b in g.nodes and b not in g.up[a]:
            g.up[a].append(b); g.down[b].append(a)
    return g

def has_cycle(g: DagStore) -> bool:
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {}
    def dfs(n: str) -> bool:
        color[n] = GRAY
        for nb in g.up[n]:
            st = color.get(nb, WHITE)
            if st == GRAY: return True
            if st == WHITE and dfs(nb): return True
        color[n] = BLACK
        return False
    return any(color.get(t, WHITE) == WHITE and dfs(t) for t in sorted(g.nodes))

def parallel_waves(g: DagStore) -> list[list[str]] | None:
    if has_cycle(g): return None
    indeg = {t: len(g.down[t]) for t in g.nodes}
    waves: list[list[str]] = []
    ready = sorted([t for t, d in indeg.items() if d == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for t in ready:
            for dep in g.up[t]:
                indeg[dep] -= 1
                if indeg[dep] == 0: nxt.append(dep)
        ready = sorted(nxt)
    return waves if sum(len(w) for w in waves) == len(g.nodes) else None
