"""DevilTea/deviltea-labs#13 — Widget Lab semantic dependency graph closure.

Hand-rolled parent pointers and child adjacency for cross-widget dependency
validation before Runtime compilation.
"""

from __future__ import annotations

from collections import deque


class WidgetGraph:
    def __init__(self) -> None:
        self.widgets: set[str] = set()
        self.parent: dict[str, str] = {}
        self.children: dict[str, list[str]] = {}


def load_widget_graph(
    widgets: list[str],
    depends: list[tuple[str, str]],
) -> WidgetGraph:
    g = WidgetGraph()
    for wid in widgets:
        g.widgets.add(wid)
        g.children.setdefault(wid, [])
    for parent, child in depends:
        if parent not in g.widgets or child not in g.widgets:
            continue
        g.parent[child] = parent
        g.children.setdefault(parent, []).append(child)
        g.children.setdefault(child, g.children.get(child, []))
    return g


def _collect_descendants(g: WidgetGraph, root: str, acc: set[str]) -> None:
    for ch in sorted(g.children.get(root, [])):
        if ch in acc:
            continue
        acc.add(ch)
        _collect_descendants(g, ch, acc)


def transitive_deps(g: WidgetGraph, widget_id: str) -> list[str]:
    if widget_id not in g.widgets:
        return []
    seen: set[str] = {widget_id}
    work: deque[str] = deque(g.children.get(widget_id, []))
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.children.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    closure: set[str] = set(seen)
    _collect_descendants(g, widget_id, closure)
    return sorted(closure)


def compile_blockers(g: WidgetGraph, widget_id: str) -> list[str]:
    if widget_id not in g.widgets:
        return []
    chain: list[str] = [widget_id]
    claimed: set[str] = {widget_id}
    cur = widget_id
    while True:
        parent = g.parent.get(cur)
        if parent is None or parent in claimed:
            break
        claimed.add(parent)
        chain.append(parent)
        cur = parent
    return chain
