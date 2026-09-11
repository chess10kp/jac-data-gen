"""dullage/flatnotes#301 — Search/index .md files recursively.

Hand-rolled parent/child maps, deque BFS with a visited set, and extension
filtering for recursive markdown discovery under a notes root.
"""

from __future__ import annotations

from collections import deque


class VfsStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._kind: dict[str, str] = {}
        self._nodes: set[str] = set()


def load_vfs(entries: list[tuple[str, str, str | None]]) -> VfsStore:
    # (path, kind folder|file, parent_path)
    g = VfsStore()
    for path, kind, _par in entries:
        g._nodes.add(path)
        g._parent.setdefault(path, None)
        g._children.setdefault(path, [])
        g._kind[path] = kind
    for path, kind, par in entries:
        g._kind[path] = kind
        if par is not None and par in g._nodes:
            old = g._parent.get(path)
            if old is not None and old != par:
                g._children[old] = [c for c in g._children[old] if c != path]
            g._parent[path] = par
            if path not in g._children[par]:
                g._children[par].append(path)
    return g


def index_markdown(g: VfsStore, root: str) -> list[str]:
    if root not in g._nodes or g._kind.get(root) != "folder":
        return []
    hits: list[str] = []
    claimed: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        for ch in sorted(g._children.get(cur, [])):
            if ch in claimed:
                continue
            if g._kind.get(ch) == "file":
                if ch.endswith(".md"):
                    hits.append(ch)
            else:
                queue.append(ch)
    return sorted(hits)
