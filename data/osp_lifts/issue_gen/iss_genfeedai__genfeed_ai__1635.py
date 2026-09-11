"""genfeedai/genfeed.ai#1635 — module import reachability for dependency reconciliation.

Positive Fallow findings require knowing which modules are reachable from
entry points versus orphaned imports. The store keeps an adjacency dict and
walks it with an explicit stack plus visited set; cycles must not truncate.
"""

from __future__ import annotations


class ModuleGraph:
    def __init__(self) -> None:
        self.modules: dict[str, bool] = {}
        self.imports: dict[str, list[str]] = {}

    def add_module(self, name: str) -> None:
        self.modules[name] = True
        self.imports.setdefault(name, [])

    def add_import(self, src: str, dst: str) -> None:
        if src in self.modules and dst in self.modules:
            self.imports[src].append(dst)


def load_modules(
    modules: list[str],
    edges: list[tuple[str, str]],
) -> ModuleGraph:
    g = ModuleGraph()
    for m in modules:
        g.add_module(m)
    for src, dst in edges:
        g.add_import(src, dst)
    return g


def reachable_from_entries(g: ModuleGraph, entries: list[str]) -> list[str]:
    seen: set[str] = set()
    stack: list[str] = []
    for e in entries:
        if e in g.modules:
            stack.append(e)
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.imports.get(cur, []):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(seen)


def orphan_modules(g: ModuleGraph, entries: list[str]) -> list[str]:
    reach = set(reachable_from_entries(g, entries))
    return sorted(m for m in g.modules if m not in reach)
