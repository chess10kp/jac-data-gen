"""PostHog/posthog#64387 — Flag dependency blast-radius resolver."""

from __future__ import annotations

from collections import deque


class FlagStore:
    # Adjacency dict for flag_evaluates_to dependency chains.
    def __init__(self) -> None:
        self._flags: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_flags(
    flag_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> FlagStore:
    fs = FlagStore()
    for fid in flag_ids:
        fs._flags.add(fid)
        fs._depends.setdefault(fid, [])
    for parent, dep in depends_edges:
        if parent in fs._flags and dep in fs._flags:
            fs._depends.setdefault(parent, []).append(dep)
            fs._depends.setdefault(dep, fs._depends.get(dep, []))
    return fs


def _walk_deps(store: FlagStore, root: str, acc: set[str], seen: set[str]) -> None:
    for dep in store._depends.get(root, []):
        if dep in seen:
            continue
        seen.add(dep)
        acc.add(dep)
        _walk_deps(store, dep, acc, seen)


def resolve_dependency_chain(
    store: FlagStore,
    flag_id: str,
    _seen: set[str] | None = None,
) -> list[str] | None:
    if flag_id not in store._flags:
        return None
    seen = set(_seen or [])
    if flag_id in seen:
        return None
    seen.add(flag_id)
    acc: set[str] = set()
    queue: deque[str] = deque([flag_id])
    visited: set[str] = {flag_id}
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            if dep in seen:
                return None
            if dep not in visited:
                visited.add(dep)
                acc.add(dep)
                queue.append(dep)
    extra: set[str] = set(acc)
    _walk_deps(store, flag_id, extra, set(seen))
    return sorted(extra)


def blast_radius_ids(store: FlagStore, flag_id: str) -> list[str]:
    chain = resolve_dependency_chain(store, flag_id, set())
    if chain is None:
        return []
    out = set(chain)
    out.add(flag_id)
    return sorted(out)


def missing_dependency(store: FlagStore, flag_id: str, dep_key: str) -> bool:
    if flag_id not in store._flags:
        return True
    return dep_key not in store._flags
