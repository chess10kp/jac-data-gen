"""antst/go-apispec#76 — Gin call-graph reachability for OpenAPI path export.

Large Gin projects form mutual handler cycles; apispec must still collect
route paths reachable from engine entry handlers despite cycles in Calls.
"""

from __future__ import annotations

from collections import deque


class CallGraph:
    # Fresh handle per test; hand-rolled adjacency for Calls + route registry.
    def __init__(self) -> None:
        self.handlers: dict[str, bool] = {}
        self.calls: dict[str, list[str]] = {}
        self.routes: dict[str, list[str]] = {}
        self.entries: list[str] = []


def load_callgraph(
    handlers: list[str],
    calls: list[tuple[str, str]],
    routes: list[tuple[str, str]],
    entries: list[str],
) -> CallGraph:
    g = CallGraph()
    for h in handlers:
        g.handlers[h] = True
        g.calls.setdefault(h, [])
        g.routes.setdefault(h, [])
    for src, dst in calls:
        if src in g.handlers and dst in g.handlers:
            g.calls[src].append(dst)
    for handler, path in routes:
        if handler in g.handlers:
            g.routes[handler].append(path)
    g.entries = list(entries)
    return g


def reachable_handlers(g: CallGraph, entry: str) -> list[str]:
    # Queue walk with once-only seen set; cycles must not truncate closure.
    if entry not in g.handlers:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([entry])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.calls.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)


def exported_paths(g: CallGraph) -> list[str]:
    reachable: set[str] = set()
    for entry in g.entries:
        reachable.update(reachable_handlers(g, entry))
    paths: list[str] = []
    for handler in sorted(reachable):
        for path in g.routes.get(handler, []):
            paths.append(path)
    return sorted(paths)
