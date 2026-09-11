"""Growth-Circle/cadis#259 — directory index walk with symlink cycle guard."""

from __future__ import annotations

from collections import deque

MAX_WALK = 128


class DirIndex:
    def __init__(self) -> None:
        self._dirs: set[str] = set()
        self._children: dict[str, list[str]] = {}
        self._symlinks: dict[str, str] = {}


def load_dir_index(
    dirs: list[str],
    child_edges: list[tuple[str, str]],
    symlinks: list[tuple[str, str]] | None = None,
) -> DirIndex:
    idx = DirIndex()
    for d in dirs:
        idx._dirs.add(d)
        idx._children.setdefault(d, [])
    for parent, child in child_edges:
        if parent in idx._dirs and child in idx._dirs:
            idx._children.setdefault(parent, []).append(child)
    if symlinks:
        for link, target in symlinks:
            if link in idx._dirs and target in idx._dirs:
                idx._symlinks[link] = target
    return idx


def indexed_paths(idx: DirIndex, root: str) -> list[str]:
    if root not in idx._dirs:
        return []
    visited: set[str] = set()
    out: list[str] = []
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_WALK:
        steps += 1
        cur = queue.popleft()
        canon = cur
        link_seen: set[str] = set()
        while canon in idx._symlinks:
            if canon in link_seen:
                break
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            continue
        visited.add(canon)
        out.append(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return sorted(out)


def walk_terminates(idx: DirIndex, root: str) -> bool:
    if root not in idx._dirs:
        return True
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue:
        if steps >= MAX_WALK:
            return False
        steps += 1
        cur = queue.popleft()
        canon = cur
        link_seen: set[str] = set()
        while canon in idx._symlinks:
            if canon in link_seen:
                return True
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            continue
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return True


def cycle_detected(idx: DirIndex, root: str) -> bool:
    if root not in idx._dirs:
        return False
    visited: set[str] = set()
    queue: deque[str] = deque([root])
    steps = 0
    while queue and steps < MAX_WALK:
        steps += 1
        cur = queue.popleft()
        link_seen: set[str] = set()
        canon = cur
        while canon in idx._symlinks:
            if canon in link_seen:
                return True
            link_seen.add(canon)
            canon = idx._symlinks[canon]
        if canon in visited:
            return True
        visited.add(canon)
        for child in idx._children.get(canon, []):
            queue.append(child)
        if cur in idx._symlinks:
            queue.append(idx._symlinks[cur])
    return False
