"""ryjen/mediapipe#7 — GenAI capability dependency reachability."""

from __future__ import annotations

from collections import deque


class CapabilityGraph:
    def __init__(self) -> None:
        self._features: set[str] = set()
        self._requires: dict[str, list[str]] = {}
        self._supported: set[str] = set()


def load_capability_graph(
    features: list[str],
    requires: list[tuple[str, str]],
    supported: list[str],
) -> CapabilityGraph:
    g = CapabilityGraph()
    for f in features:
        g._features.add(f)
        g._requires.setdefault(f, [])
    for feat, req in requires:
        if feat in g._features and req in g._features:
            g._requires.setdefault(feat, []).append(req)
    g._supported = set(supported)
    return g


def available_features(graph: CapabilityGraph) -> list[str]:
    ok: list[str] = []
    for feat in sorted(graph._features):
        reqs = graph._requires.get(feat, [])
        if all(r in graph._supported for r in reqs) and feat in graph._supported:
            ok.append(feat)
    return ok


def dependency_closure(graph: CapabilityGraph, feature: str) -> list[str]:
    if feature not in graph._features:
        return []
    seen: set[str] = {feature}
    queue: deque[str] = deque([feature])
    while queue:
        cur = queue.popleft()
        for req in graph._requires.get(cur, []):
            if req not in seen:
                seen.add(req)
                queue.append(req)
    return sorted(seen)


def blocked_by_missing(graph: CapabilityGraph, feature: str) -> list[str]:
    if feature not in graph._features:
        return []
    missing: set[str] = set()
    for req in dependency_closure(graph, feature):
        if req not in graph._supported:
            missing.add(req)
    return sorted(missing)
