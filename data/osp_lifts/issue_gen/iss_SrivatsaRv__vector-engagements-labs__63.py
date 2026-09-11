"""SrivatsaRv/vector-engagements-labs#63 — Change-aware test layer dependency reachability."""

from __future__ import annotations

from collections import deque


class LayerStore:
    # DAG adjacency for CI test layer depends_on relationships.
    def __init__(self) -> None:
        self._layers: set[str] = set()
        self._depends: dict[str, list[str]] = {}


def load_layers(
    layer_names: list[str],
    depends_edges: list[tuple[str, str]],
) -> LayerStore:
    store = LayerStore()
    for name in layer_names:
        store._layers.add(name)
        store._depends.setdefault(name, [])
    for upstream, downstream in depends_edges:
        if upstream in store._layers and downstream in store._layers:
            store._depends.setdefault(downstream, []).append(upstream)
    return store


def required_layers(store: LayerStore, changed: list[str]) -> list[str]:
    result: set[str] = set()
    for layer in changed:
        if layer not in store._layers:
            continue
        seen: set[str] = {layer}
        queue: deque[str] = deque([layer])
        while queue:
            cur = queue.popleft()
            result.add(cur)
            for dep in store._depends.get(cur, []):
                if dep not in seen:
                    seen.add(dep)
                    queue.append(dep)
    return sorted(result)


def has_cycle(store: LayerStore) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        visited.add(node)
        stack.add(node)
        for dep in store._depends.get(node, []):
            if dep in stack:
                return True
            if dep not in visited and dfs(dep):
                return True
        stack.remove(node)
        return False

    for layer in sorted(store._layers):
        if layer not in visited and dfs(layer):
            return True
    return False


def transitive_deps(store: LayerStore, layer: str) -> list[str]:
    if layer not in store._layers:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([layer])
    while queue:
        cur = queue.popleft()
        for dep in store._depends.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    return sorted(seen)
