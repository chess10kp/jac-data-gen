"""NewChoBo/workbench-kit#286 — Agent Harness governance resource tree."""

from __future__ import annotations


class HarnessStore:
    # Parent pointers and children adjacency for governance resources.
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._children_of: dict[str, list[str]] = {}


def load_harness(resources: list[tuple[str, str | None]]) -> HarnessStore:
    store = HarnessStore()
    for name, parent in resources:
        if parent is not None and parent not in store._parent_of:
            raise KeyError("unknown parent resource")
        store._parent_of[name] = parent
        store._children_of.setdefault(name, [])
        if parent is not None:
            store._children_of.setdefault(parent, []).append(name)
    return store


def _collect_ancestors(store: HarnessStore, name: str) -> list[str]:
    chain: list[str] = []
    cur: str | None = name
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent_of.get(cur)
    return chain


def governance_chain(store: HarnessStore, resource: str) -> list[str]:
    if resource not in store._parent_of:
        return []
    return list(reversed(_collect_ancestors(store, resource)))


def descendant_resources(store: HarnessStore, root: str) -> list[str]:
    if root not in store._parent_of:
        return []
    stack = [root]
    seen: set[str] = set()
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children_of.get(cur, []):
            stack.append(ch)
    return sorted(out)


def has_cycle(store: HarnessStore) -> bool:
    for start in store._parent_of:
        seen: set[str] = set()
        cur: str | None = start
        while cur is not None:
            if cur in seen:
                return True
            seen.add(cur)
            cur = store._parent_of.get(cur)
    return False
