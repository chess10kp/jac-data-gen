"""EffortlessMetrics/perl-lsp-swarm#12527 — compile-time module dependency closure."""

from __future__ import annotations

from collections import deque


class ProjectStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.nodes: set[str] = set()


def load_project(
    modules: list[str],
    use_edges: list[tuple[str, str]],
) -> ProjectStore:
    # use_edges: (consumer, dependency) compile-time use/require
    g = ProjectStore()
    for mid in modules:
        g.nodes.add(mid)
        g.deps.setdefault(mid, [])
    for consumer, dep in use_edges:
        if consumer in g.nodes and dep in g.nodes and dep not in g.deps[consumer]:
            g.deps[consumer].append(dep)
    return g


def _has_cycle(g: ProjectStore) -> bool:
    white, gray, black = 0, 1, 2
    color: dict[str, int] = {}

    def dfs(n: str) -> bool:
        color[n] = gray
        for dep in g.deps.get(n, []):
            st = color.get(dep, white)
            if st == gray:
                return True
            if st == white and dfs(dep):
                return True
        color[n] = black
        return False

    return any(color.get(t, white) == white and dfs(t) for t in sorted(g.nodes))


def module_closure(g: ProjectStore, module: str) -> list[str]:
    if module not in g.nodes:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([module])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(g.deps.get(cur, [])):
            if dep not in seen:
                q.append(dep)
    return sorted(seen)


def compile_waves(g: ProjectStore) -> list[list[str]] | None:
    if _has_cycle(g):
        return None
    indeg = {m: len(g.deps.get(m, [])) for m in g.nodes}
    waves: list[list[str]] = []
    ready = sorted([m for m, d in indeg.items() if d == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for nm in ready:
            for consumer in g.nodes:
                if nm in g.deps.get(consumer, []):
                    indeg[consumer] -= 1
                    if indeg[consumer] == 0:
                        nxt.append(consumer)
        ready = sorted(nxt)
    total = sum(len(w) for w in waves)
    return waves if total == len(g.nodes) else None


def has_import_cycle(g: ProjectStore) -> bool:
    return _has_cycle(g)
