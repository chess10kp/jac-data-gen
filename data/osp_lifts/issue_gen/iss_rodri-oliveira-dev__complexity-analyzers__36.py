"""rodri-oliveira-dev/complexity-analyzers#36 — analyzer execution order waves."""

from __future__ import annotations

from collections import deque


class AnalyzerStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.analyzers: set[str] = set()


def load_analyzers(
    analyzers: list[str],
    requires: list[tuple[str, str]],
) -> AnalyzerStore:
    store = AnalyzerStore()
    for name in analyzers:
        store.analyzers.add(name)
        store.deps.setdefault(name, [])
    for dst, src in requires:
        if dst in store.analyzers and src in store.analyzers:
            if src not in store.deps[dst]:
                store.deps[dst].append(src)
    return store


def execution_waves(store: AnalyzerStore) -> list[list[str]] | None:
    indeg = {name: len(store.deps.get(name, [])) for name in store.analyzers}
    waves: list[list[str]] = []
    ready = sorted([name for name, deg in indeg.items() if deg == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for base in ready:
            for target in store.analyzers:
                if base in store.deps.get(target, []):
                    indeg[target] -= 1
                    if indeg[target] == 0:
                        nxt.append(target)
        ready = sorted(nxt)
    return waves if sum(len(w) for w in waves) == len(store.analyzers) else None


def required_analyzers(store: AnalyzerStore, analyzer: str) -> list[str]:
    if analyzer not in store.analyzers:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([analyzer])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(store.deps.get(cur, [])):
            if dep not in seen:
                q.append(dep)
    seen.discard(analyzer)
    return sorted(seen)
