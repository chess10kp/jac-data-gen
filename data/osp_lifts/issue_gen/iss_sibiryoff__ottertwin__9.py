"""sibiryoff/ottertwin#9 — directory-aware recursive copy planning with cycle guard."""

from __future__ import annotations


class FsStore:
    def __init__(self) -> None:
        self._entries: set[str] = set()
        self._is_dir: dict[str, bool] = {}
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}


def load_fs_tree(
    entries: list[str],
    is_dir: dict[str, bool],
    parent_edges: list[tuple[str, str | None]],
) -> FsStore:
    store = FsStore()
    for path in entries:
        store._entries.add(path)
        store._is_dir[path] = is_dir.get(path, False)
        store._children.setdefault(path, [])
    for path, par in parent_edges:
        if path not in store._entries:
            continue
        store._parent[path] = par
        if par is not None and par in store._entries:
            store._children.setdefault(par, []).append(path)
    return store


def _plan_recursive(
    store: FsStore,
    dir_path: str,
    seen: set[str],
    plan: list[str],
) -> None:
    if dir_path in seen:
        return
    seen.add(dir_path)
    plan.append(dir_path)
    for child in sorted(store._children.get(dir_path, [])):
        if store._is_dir.get(child, False):
            _plan_recursive(store, child, seen, plan)
        else:
            if child not in seen:
                seen.add(child)
                plan.append(child)


def plan_copy(store: FsStore, root_path: str) -> list[str]:
    if root_path not in store._entries:
        return []
    if not store._is_dir.get(root_path, False):
        return [root_path]
    seen: set[str] = set()
    plan: list[str] = []
    _plan_recursive(store, root_path, seen, plan)
    return plan


def collect_files(store: FsStore, dir_path: str) -> list[str]:
    plan = plan_copy(store, dir_path)
    return [p for p in plan if not store._is_dir.get(p, False)]
