"""agent-team-project/kensho-projects#17 — Workplane M2E lifecycle and dependency DAG.

Fixed work-item lifecycle with typed cross-project dependencies; only ``blocks``
edges participate in cycle detection. Derived blocking from unresolved blockers.
"""

from __future__ import annotations

from collections import deque

LIFECYCLE = frozenset({"open", "in_progress", "in_review", "done", "cancelled"})
NEXT = {
    "open": frozenset({"in_progress", "cancelled"}),
    "in_progress": frozenset({"in_review", "cancelled"}),
    "in_review": frozenset({"in_progress", "done", "cancelled"}),
    "done": frozenset(),
    "cancelled": frozenset(),
}
DEP_TYPES = frozenset({"blocks", "relates", "caused-by"})


class DependencyCycleError(Exception):
    pass


class Workplane:
    def __init__(self) -> None:
        self._items: dict[str, dict[str, object]] = {}
        self._blocks: dict[str, list[str]] = {}
        self._relates: dict[str, list[tuple[str, str]]] = {}


def load_workplane(
    items: list[tuple[str, str, int]],
    dependencies: list[tuple[str, str, str]],
) -> Workplane:
    wp = Workplane()
    for iid, state, ver in items:
        wp._items[iid] = {"state": state, "version": ver}
        wp._blocks.setdefault(iid, [])
    for src, tgt, dtype in dependencies:
        if src not in wp._items or tgt not in wp._items or dtype not in DEP_TYPES:
            continue
        if dtype == "blocks":
            wp._blocks.setdefault(tgt, []).append(src)
        else:
            wp._relates.setdefault(src, []).append((tgt, dtype))
            wp._relates.setdefault(tgt, []).append((src, dtype))
    return wp


def get_state(wp: Workplane, item_id: str) -> str | None:
    row = wp._items.get(item_id)
    return None if row is None else str(row["state"])


def _transitive_blockers(wp: Workplane, item_id: str) -> set[str]:
    seen: set[str] = set()
    work: deque[str] = deque(wp._blocks.get(item_id, []))
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for up in wp._blocks.get(cur, []):
            if up not in seen:
                work.append(up)
    return seen


def blocking_closure(wp: Workplane, item_id: str) -> list[str]:
    if item_id not in wp._items:
        return []
    return sorted(_transitive_blockers(wp, item_id))


def is_blocked(wp: Workplane, item_id: str) -> bool:
    if item_id not in wp._items:
        return False
    for bid in _transitive_blockers(wp, item_id):
        if wp._items[bid]["state"] != "done":
            return True
    return False


def would_block_cycle(wp: Workplane, blocker: str, blocked: str) -> bool:
    if blocker == blocked:
        return True
    return blocked in _transitive_blockers(wp, blocker)


def add_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> None:
    if dep_type not in DEP_TYPES:
        raise ValueError(f"unknown dependency type: {dep_type}")
    if source not in wp._items or target not in wp._items:
        return
    if dep_type == "blocks":
        if would_block_cycle(wp, source, target):
            raise DependencyCycleError("dependency_cycle")
        wp._blocks.setdefault(target, []).append(source)
        return
    wp._relates.setdefault(source, []).append((target, dep_type))
    wp._relates.setdefault(target, []).append((source, dep_type))


def remove_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> bool:
    if dep_type not in DEP_TYPES:
        raise ValueError(f"unknown dependency type: {dep_type}")
    if source not in wp._items or target not in wp._items:
        return False
    if dep_type == "blocks":
        bl = wp._blocks.get(target, [])
        if source not in bl:
            return False
        bl.remove(source)
        return True
    pairs = wp._relates.get(source, [])
    if (target, dep_type) not in pairs:
        return False
    pairs.remove((target, dep_type))
    wp._relates[target].remove((source, dep_type))
    return True


def transition(wp: Workplane, item_id: str, target: str, expected_version: int) -> int:
    row = wp._items.get(item_id)
    if row is None:
        raise KeyError(item_id)
    if int(row["version"]) != expected_version:
        raise ValueError("stale_version")
    cur = str(row["state"])
    if target not in NEXT.get(cur, frozenset()):
        raise ValueError("invalid_transition")
    if target in {"in_progress", "done"} and is_blocked(wp, item_id):
        raise ValueError("blocked")
    row["state"] = target
    row["version"] = expected_version + 1
    return int(row["version"])


def related_items(wp: Workplane, item_id: str) -> list[tuple[str, str]]:
    if item_id not in wp._items:
        return []
    return sorted(wp._relates.get(item_id, []))
