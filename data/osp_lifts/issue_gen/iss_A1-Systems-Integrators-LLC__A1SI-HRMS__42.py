"""A1-Systems-Integrators-LLC/A1SI-HRMS#42 — Project tree archive and descendants.

Hand-rolled parent pointers + child adjacency for nested project CRUD,
descendant enumeration, and cascade archive before tree serializers land.
"""

from __future__ import annotations

from collections import deque


class ProjectStore:
    def __init__(self) -> None:
        self._projects: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._active: dict[str, bool] = {}


def load_projects(
    projects: list[str],
    parent_edges: list[tuple[str, str]],
) -> ProjectStore:
    store = ProjectStore()
    for pid in projects:
        store._projects.add(pid)
        store._parent[pid] = None
        store._children.setdefault(pid, [])
        store._active[pid] = True
    for parent, child in parent_edges:
        if parent in store._projects and child in store._projects:
            store._parent[child] = parent
            store._children.setdefault(parent, []).append(child)
    return store


def _descendants(store: ProjectStore, root: str) -> list[str]:
    if root not in store._projects:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(store._children.get(root, []))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in store._children.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(seen)


def get_descendants(store: ProjectStore, project_id: str) -> list[str]:
    return _descendants(store, project_id)


def child_count(store: ProjectStore, project_id: str) -> int:
    if project_id not in store._projects:
        return 0
    return len(store._children.get(project_id, []))


def archive_project(store: ProjectStore, project_id: str) -> list[str]:
    if project_id not in store._projects:
        return []
    targets = sorted([project_id] + _descendants(store, project_id))
    for pid in targets:
        store._active[pid] = False
    return targets


def active_projects(store: ProjectStore) -> list[str]:
    return sorted(pid for pid in store._projects if store._active.get(pid, False))
