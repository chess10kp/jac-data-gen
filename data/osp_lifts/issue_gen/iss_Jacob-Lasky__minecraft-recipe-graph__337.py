"""Jacob-Lasky/minecraft-recipe-graph#337 — widget parent hover tree walk."""

from __future__ import annotations

MAX_HOVER = 64


class WidgetTree:
    def __init__(self) -> None:
        self._widgets: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._hovered: str | None = None


def load_widgets(
    widgets: list[str],
    parent_edges: list[tuple[str, str]],
    hovered_id: str | None = None,
) -> WidgetTree:
    tree = WidgetTree()
    for wid in widgets:
        tree._widgets.add(wid)
        tree._parent[wid] = None
        tree._children.setdefault(wid, [])
    for parent, child in parent_edges:
        if parent in tree._widgets and child in tree._widgets:
            tree._parent[child] = parent
            tree._children.setdefault(parent, []).append(child)
    if hovered_id in tree._widgets:
        tree._hovered = hovered_id
    return tree


def hovered_ancestors(store: WidgetTree) -> list[str]:
    if store._hovered is None:
        return []
    chain: list[str] = []
    seen: set[str] = set()
    cur: str | None = store._hovered
    while cur is not None and cur in store._widgets:
        if cur in seen:
            break
        if len(chain) >= MAX_HOVER:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent.get(cur)
    return chain


def hover_depth(store: WidgetTree) -> int:
    anc = hovered_ancestors(store)
    return max(len(anc) - 1, 0)


def safe_hover_ids(store: WidgetTree) -> list[str]:
    if store._hovered is None:
        return []
    seen: set[str] = set()
    out: list[str] = []
    queue = list(store._children.get(store._hovered, []))
    while queue and len(out) < MAX_HOVER:
        cur = queue.pop(0)
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children.get(cur, []):
            if ch not in seen:
                queue.append(ch)
    return sorted(out)
