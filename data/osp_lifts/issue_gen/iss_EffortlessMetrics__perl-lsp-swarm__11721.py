"""EffortlessMetrics/perl-lsp-swarm#11721 — stable stage/decision/ownership contract."""

from __future__ import annotations

from collections import deque


class PipelineStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.owners: dict[str, str] = {}
        self.nodes: set[str] = set()


def load_pipeline(
    stages: list[tuple[str, str]],
    hard_deps: list[tuple[str, str]],
) -> PipelineStore:
    # (stage_id, owner); hard_deps = (stage, depends_on)
    g = PipelineStore()
    for sid, owner in stages:
        g.nodes.add(sid)
        g.owners[sid] = owner
        g.deps.setdefault(sid, [])
    for stage, dep in hard_deps:
        if stage in g.nodes and dep in g.nodes and dep not in g.deps[stage]:
            g.deps[stage].append(dep)
    return g


def _has_cycle(g: PipelineStore) -> bool:
    white, gray, black = 0, 1, 2
    color: dict[str, int] = {}

    def dfs(n: str) -> bool:
        color[n] = gray
        for upstream in g.deps.get(n, []):
            st = color.get(upstream, white)
            if st == gray:
                return True
            if st == white and dfs(upstream):
                return True
        color[n] = black
        return False

    return any(color.get(t, white) == white and dfs(t) for t in sorted(g.nodes))


def stage_order(g: PipelineStore) -> list[list[str]] | None:
    if _has_cycle(g):
        return None
    indeg = {t: len(g.deps.get(t, [])) for t in g.nodes}
    waves: list[list[str]] = []
    ready = sorted([t for t, d in indeg.items() if d == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for t in ready:
            for stage in g.nodes:
                if t in g.deps.get(stage, []):
                    indeg[stage] -= 1
                    if indeg[stage] == 0:
                        nxt.append(stage)
        ready = sorted(nxt)
    total = sum(len(w) for w in waves)
    return waves if total == len(g.nodes) else None


def owners_for(g: PipelineStore, stage: str) -> list[str]:
    if stage not in g.nodes:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([stage])
    owners: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        owners.add(g.owners[cur])
        for dep in sorted(g.deps.get(cur, [])):
            if dep not in seen:
                q.append(dep)
    return sorted(owners)
