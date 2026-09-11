"""creator-signal/fork-CoreBunch-Instatic#12 — recursive media folder upload."""

from __future__ import annotations

from collections import deque

MEDIA_EXT = {".png", ".jpg", ".mp4", ".wav"}


class FsGraph:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._kind: dict[str, str] = {}
        self._nodes: set[str] = set()


def load_fs(entries: list[tuple[str, str, str | None]]) -> FsGraph:
    # (path, kind folder|file, parent_path)
    g = FsGraph()
    for path, kind, _par in entries:
        g._nodes.add(path)
        g._parent.setdefault(path, None)
        g._children.setdefault(path, [])
        g._kind[path] = kind
    for path, _kind, par in entries:
        if par is not None and par in g._nodes:
            g._parent[path] = par
            g._children.setdefault(par, []).append(path)
    return g


def list_media(g: FsGraph, root_path: str) -> list[str]:
    if root_path not in g._nodes or g._kind.get(root_path) != "folder":
        return []
    out: list[str] = []
    queue: deque[str] = deque([root_path])
    seen: set[str] = {root_path}
    while queue:
        cur = queue.popleft()
        for ch in sorted(g._children.get(cur, [])):
            if ch in seen:
                continue
            seen.add(ch)
            if g._kind.get(ch) == "file":
                ext = ch[ch.rfind(".") :] if "." in ch else ""
                if ext in MEDIA_EXT:
                    out.append(ch)
            else:
                queue.append(ch)
    return sorted(out)


def upload_queue(g: FsGraph, drops: list[str]) -> list[str]:
    planned: list[str] = []
    for drop in sorted(drops):
        planned.extend(list_media(g, drop))
    return sorted(set(planned))
