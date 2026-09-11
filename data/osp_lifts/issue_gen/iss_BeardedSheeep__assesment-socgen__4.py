"""BeardedSheeep/assesment-socgen#4 — Docker layer rebuild dependency graph."""

from collections import deque


class LayerGraph:
    def __init__(self) -> None:
        self._layers: set[str] = set()
        self._deps: dict[str, list[str]] = {}


def load_layers(layers: list[str], deps: list[tuple[str, str]]) -> LayerGraph:
    g = LayerGraph()
    for name in layers:
        g._layers.add(name)
        g._deps.setdefault(name, [])
    for base, upper in deps:
        if base in g._layers and upper in g._layers:
            g._deps.setdefault(upper, []).append(base)
    return g


def invalidated_by(store: LayerGraph, changed: str) -> list[str]:
    if changed not in store._layers:
        return []
    seen: set[str] = {changed}
    queue: deque[str] = deque([changed])
    out: set[str] = set()
    while queue:
        cur = queue.popleft()
        for name in store._layers:
            if cur in store._deps.get(name, []) and name not in seen:
                seen.add(name)
                out.add(name)
                queue.append(name)
    return sorted(out)
