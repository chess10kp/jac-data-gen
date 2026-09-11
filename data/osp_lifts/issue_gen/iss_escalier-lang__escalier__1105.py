"""escalier-lang/escalier#1105 — class extends graph cycle detection."""

from __future__ import annotations


class ExtendsCycleError(Exception):
    pass


class ClassStore:
    def __init__(self) -> None:
        self._extends: dict[str, str | None] = {}


def load_classes(
    classes: list[tuple[str, str | None]],
) -> ClassStore:
    store = ClassStore()
    for name, base in classes:
        store._extends[name] = base
    return store


def extends_chain(store: ClassStore, class_name: str) -> list[str]:
    if class_name not in store._extends:
        return []
    chain: list[str] = []
    cur: str | None = class_name
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._extends.get(cur)
    return chain


def extends_cycle_classes(store: ClassStore) -> list[str]:
    found: set[str] = set()
    for cls in sorted(store._extends):
        cur: str | None = cls
        seen: set[str] = set()
        while cur is not None:
            if cur in seen:
                found.add(cur)
                break
            seen.add(cur)
            cur = store._extends.get(cur)
    return sorted(found)


def add_extends(store: ClassStore, child: str, base: str | None) -> None:
    if base is not None:
        cur: str | None = base
        seen: set[str] = {child}
        while cur is not None:
            if cur in seen:
                raise ExtendsCycleError(f"cycle involving {child}")
            seen.add(cur)
            cur = store._extends.get(cur)
    store._extends[child] = base


def is_valid_hierarchy(store: ClassStore) -> bool:
    return len(extends_cycle_classes(store)) == 0
