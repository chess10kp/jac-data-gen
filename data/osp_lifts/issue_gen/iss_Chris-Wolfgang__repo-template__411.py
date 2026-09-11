"""Chris-Wolfgang/repo-template#411 — transitive NuGet dependency walk."""

from collections import deque


class DepGraph:
    def __init__(self) -> None:
        self._pkgs: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_packages(pkgs: list[str], edges: list[tuple[str, str]]) -> DepGraph:
    g = DepGraph()
    for p in pkgs:
        g._pkgs.add(p)
        g._deps.setdefault(p, [])
    for a, b in edges:
        if a in g._pkgs and b in g._pkgs:
            g._deps.setdefault(a, []).append(b)
    return g


def transitive_deps(store: DepGraph, pkg: str) -> list[str]:
    if pkg not in store._pkgs:
        return []
    seen: set[str] = {pkg}
    queue: deque[str] = deque([pkg])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for d in store._deps.get(cur, []):
            out.add(d)
            if d not in seen:
                seen.add(d)
                queue.append(d)
    return sorted(out)
