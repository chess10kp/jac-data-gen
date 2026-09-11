"""TheLarkInn/aipm#1617 — Build performance report: memoized crate lineage and feature-trim impact.

Models Cargo compilation-unit graphs with memoized version lineage, gated dependency
edges (jsonschema TLS chain), and estimating units dropped when trimming features.
"""

from __future__ import annotations

from collections import deque


class BuildReportGraph:
    def __init__(self) -> None:
        self.times: dict[str, float] = {}
        self.build_script: dict[str, bool] = {}
        self.gated_deps: dict[str, list[tuple[str, str]]] = {}
        self.lineage: dict[str, str] = {}
        self._ancestor_memo: dict[str, list[str]] = {}


def load_build_report_graph(
    units: list[tuple[str, float, bool]],
    gated_edges: list[tuple[str, str, str]],
    lineage_edges: list[tuple[str, str]],
) -> BuildReportGraph:
    g = BuildReportGraph()
    for name, secs, is_bs in units:
        g.times[name] = secs
        g.build_script[name] = is_bs
        g.gated_deps.setdefault(name, [])
    for consumer, dep, gate in gated_edges:
        if consumer in g.gated_deps and dep in g.times:
            g.gated_deps[consumer].append((dep, gate))
    for child, parent in lineage_edges:
        if child in g.times:
            g.lineage[child] = parent
    return g


def memo_ancestors(g: BuildReportGraph, unit: str) -> list[str]:
    if unit not in g.times:
        return []
    if unit in g._ancestor_memo:
        return g._ancestor_memo[unit]
    chain: list[str] = []
    seen: set[str] = set()
    cur = g.lineage.get(unit, "")
    while cur and cur not in seen:
        seen.add(cur)
        chain.append(cur)
        cur = g.lineage.get(cur, "")
    out = sorted(chain)
    g._ancestor_memo[unit] = out
    return out


def _reachable(g: BuildReportGraph, root: str, trimmed: set[str] | None) -> set[str]:
    trimmed = trimmed or set()
    if root not in g.times:
        return set()
    seen: set[str] = {root}
    q: deque[str] = deque([root])
    while q:
        u = q.popleft()
        for dep, gate in g.gated_deps.get(u, []):
            if gate and gate in trimmed:
                continue
            if dep not in seen:
                seen.add(dep)
                q.append(dep)
    return seen


def transitive_build_deps(
    g: BuildReportGraph,
    root: str,
    trimmed_features: list[str] | None = None,
) -> list[str]:
    reach = _reachable(g, root, set(trimmed_features or []))
    reach.discard(root)
    return sorted(reach)


def units_blocked_by_trim(
    g: BuildReportGraph,
    root: str,
    trimmed_features: list[str],
) -> list[str]:
    if root not in g.times:
        return []
    before = _reachable(g, root, set())
    after = _reachable(g, root, set(trimmed_features))
    return sorted(before - after)


def trim_time_savings(
    g: BuildReportGraph,
    root: str,
    trimmed_features: list[str],
) -> float:
    blocked = units_blocked_by_trim(g, root, trimmed_features)
    return round(sum(g.times[u] for u in blocked), 1)


def build_script_hotspots(
    g: BuildReportGraph,
    threshold: float,
) -> list[tuple[str, float]]:
    rows = [
        (name, g.times[name])
        for name in g.times
        if g.build_script.get(name) and g.times[name] >= threshold
    ]
    return sorted(rows, key=lambda row: (-row[1], row[0]))
