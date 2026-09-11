"""TheLarkInn/aipm#1531 — transitive crate dependency reachability from workspace roots.

Build performance analysis needs the transitive dependency closure of workspace
root crates. The graph uses an adjacency dict and explicit stack walk with a
visited set; duplicate crate versions appear as distinct nodes.
"""

from __future__ import annotations


class CrateGraph:
    def __init__(self) -> None:
        self.crates: dict[str, bool] = {}
        self.deps: dict[str, list[str]] = {}

    def add_crate(self, name: str) -> None:
        self.crates[name] = True
        self.deps.setdefault(name, [])

    def add_dep(self, src: str, dst: str) -> None:
        if src in self.crates and dst in self.crates:
            self.deps[src].append(dst)


def load_crates(
    crates: list[str],
    edges: list[tuple[str, str]],
) -> CrateGraph:
    g = CrateGraph()
    for c in crates:
        g.add_crate(c)
    for src, dst in edges:
        g.add_dep(src, dst)
    return g


def transitive_deps(g: CrateGraph, root: str) -> list[str]:
    if root not in g.crates:
        return []
    seen: set[str] = set()
    stack: list[str] = [root]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.deps.get(cur, []):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(seen)


def on_critical_path(g: CrateGraph, roots: list[str], target: str) -> bool:
    if target not in g.crates:
        return False
    for r in roots:
        if target in transitive_deps(g, r):
            return True
    return False
