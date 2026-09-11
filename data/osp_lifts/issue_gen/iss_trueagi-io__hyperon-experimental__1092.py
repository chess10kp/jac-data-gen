"""trueagi-io/hyperon-experimental#1092 — bounded supertype and import closure."""

from __future__ import annotations


class TypeStore:
    def __init__(self) -> None:
        self._types: set[str] = set()
        self._supertype: dict[str, list[str]] = {}
        self._imports: dict[str, list[str]] = {}


def load_type_graph(
    types: list[str],
    supertypes: list[tuple[str, str]],
    imports: list[tuple[str, str]] | None = None,
) -> TypeStore:
    store = TypeStore()
    for name in types:
        store._types.add(name)
        store._supertype.setdefault(name, [])
        store._imports.setdefault(name, [])
    for sub, sup in supertypes:
        if sub in store._types and sup in store._types:
            store._supertype.setdefault(sub, []).append(sup)
    if imports:
        for src, dst in imports:
            if src in store._types and dst in store._types:
                store._imports.setdefault(src, []).append(dst)
    return store


def _collect_bounded(
    store: TypeStore,
    start: str,
    max_depth: int,
    seen: set[str],
    acc: set[str],
    depth: int,
) -> None:
    if depth > max_depth or start in seen:
        return
    seen.add(start)
    for sup in sorted(store._supertype.get(start, [])):
        if sup in acc:
            continue
        if depth + 1 > max_depth:
            continue
        acc.add(sup)
        _collect_bounded(store, sup, max_depth, seen, acc, depth + 1)


def collect_supertypes(store: TypeStore, type_name: str, max_depth: int) -> list[str]:
    if type_name not in store._types or max_depth < 0:
        return []
    seen: set[str] = set()
    acc: set[str] = set()
    _collect_bounded(store, type_name, max_depth, seen, acc, 0)
    return sorted(acc)


def detect_mutual_import(store: TypeStore, module_a: str, module_b: str) -> bool:
    seen: set[str] = set()
    stack = [module_a]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in store._imports.get(cur, []):
            if nxt == module_b and cur == module_a:
                return True
            if nxt not in seen:
                stack.append(nxt)
    return module_b in store._imports.get(module_a, []) and module_a in store._imports.get(module_b, [])
