"""michaelwilhelmsen/humla#157 — tree-structured Folders with reparent cycle guard."""

from __future__ import annotations

from collections import deque


class FolderStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}


def load_folders(specs: list[tuple[str, str | None]]) -> FolderStore:
    g = FolderStore()
    for path, _par in specs:
        g._parent.setdefault(path, None)
        g._children.setdefault(path, [])
    for path, par in specs:
        if par is not None:
            if par not in g._parent:
                raise KeyError(par)
            g._parent[path] = par
            g._children.setdefault(par, []).append(path)
    return g


def _norm(path: str) -> str:
    p = path if path.startswith("/") else "/" + path
    return p if p == "/" else p.rstrip("/")


def resolve_path(g: FolderStore, path: str) -> str | None:
    if not path:
        return None
    p = _norm(path)
    return p if p in g._parent else None


def list_children(g: FolderStore, folder: str) -> list[str]:
    fp = resolve_path(g, folder)
    if fp is None:
        return []
    return sorted(g._children.get(fp, []))


def mkdir(g: FolderStore, parent: str, name: str) -> str | None:
    par = resolve_path(g, parent)
    if par is None:
        return None
    child = ("/" + name.strip("/")) if par == "/" else f"{par}/{name.strip('/')}"
    if child in g._parent:
        raise ValueError(f"duplicate: {child}")
    g._parent[child] = par
    g._children.setdefault(par, []).append(child)
    g._children.setdefault(child, [])
    return child


def ancestors(g: FolderStore, folder: str) -> list[str]:
    fp = resolve_path(g, folder)
    if fp is None:
        raise KeyError(folder)
    out: list[str] = []
    seen: set[str] = set()
    cur = g._parent.get(fp)
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        out.append(cur)
        cur = g._parent.get(cur)
    return out


def subtree_paths(g: FolderStore, folder: str) -> list[str]:
    fp = resolve_path(g, folder)
    if fp is None:
        return []
    q: deque[str] = deque(g._children.get(fp, []))
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in g._children.get(cur, []):
            if ch not in claimed:
                q.append(ch)
    return sorted(hits)


def would_reparent_cycle(g: FolderStore, folder: str, new_parent: str | None) -> bool:
    fp = resolve_path(g, folder)
    if fp is None:
        raise KeyError(folder)
    if new_parent is None:
        return False
    np = resolve_path(g, new_parent)
    if np is None:
        raise KeyError(new_parent)
    if np == fp:
        return True
    return fp in ancestors(g, new_parent)


def reparent(g: FolderStore, folder: str, new_parent: str | None) -> None:
    fp = resolve_path(g, folder)
    if fp is None:
        raise KeyError(folder)
    if new_parent is not None and would_reparent_cycle(g, folder, new_parent):
        raise ValueError("cycle")
    old = g._parent[fp]
    if old is not None:
        g._children[old] = [c for c in g._children[old] if c != fp]
    g._parent[fp] = new_parent
    if new_parent is not None:
        g._children.setdefault(new_parent, []).append(fp)
