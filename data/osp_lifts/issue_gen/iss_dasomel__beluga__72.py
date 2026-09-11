"""dasomel/beluga#72 — Silver/Gold transformation DAG and engine selection."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field


@dataclass
class TransformationGraph:
    transforms: dict[str, dict[str, object]] = field(default_factory=dict)
    deps: dict[str, list[str]] = field(default_factory=dict)
    reverse: dict[str, list[str]] = field(default_factory=dict)


def select_engine(
    category: str,
    *,
    stateful: bool = False,
    bounded: bool = False,
    scale: str = "medium",
) -> str:
    if stateful or category == "streaming":
        return "flink"
    if bounded or category == "lightweight_sql":
        return "duckdb"
    if category == "gold_publish":
        return "trino"
    if scale == "large" and category in ("batch_sql", "aggregation", "enrichment"):
        return "trino"
    return "airflow_sql"


def load_transformation_graph(
    transforms: list[tuple[str, str, str, dict[str, object]]],
    edges: list[tuple[str, str]],
) -> TransformationGraph:
    g = TransformationGraph()
    for tid, layer, category, attrs in transforms:
        spec: dict[str, object] = {"layer": layer, "category": category, **attrs}
        spec["engine"] = select_engine(
            category,
            stateful=bool(attrs.get("stateful", False)),
            bounded=bool(attrs.get("bounded", False)),
            scale=str(attrs.get("scale", "medium")),
        )
        g.transforms[tid] = spec
        g.deps.setdefault(tid, [])
        g.reverse.setdefault(tid, [])
    for consumer, upstream in edges:
        if consumer in g.transforms and upstream in g.transforms:
            g.deps[consumer].append(upstream)
            g.reverse[upstream].append(consumer)
    return g


def _bfs_closure(adj: dict[str, list[str]], start: str, known: set[str]) -> list[str]:
    if start not in known:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    reached: list[str] = []
    while queue:
        node = queue.popleft()
        if node in seen:
            continue
        seen.add(node)
        if node != start:
            reached.append(node)
        for nxt in sorted(adj.get(node, [])):
            if nxt not in seen:
                queue.append(nxt)
    return sorted(reached)


def upstream_transforms(g: TransformationGraph, transform_id: str) -> list[str]:
    return _bfs_closure(g.deps, transform_id, set(g.transforms))


def downstream_consumers(g: TransformationGraph, transform_id: str) -> list[str]:
    return _bfs_closure(g.reverse, transform_id, set(g.transforms))


def _dfs_paths(
    adj: dict[str, list[str]],
    source: str,
    target: str,
    *,
    max_depth: int,
) -> list[list[str]]:
    paths: list[list[str]] = []

    def walk(node: str, trail: list[str]) -> None:
        if node in trail[:-1]:
            return
        if node == target:
            paths.append(list(trail))
            return
        if len(trail) >= max_depth:
            return
        for nxt in sorted(adj.get(node, [])):
            walk(nxt, trail + [nxt])

    walk(source, [source])
    return sorted(paths)


def lineage_paths(
    g: TransformationGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in g.transforms or target not in g.transforms:
        return []
    return _dfs_paths(g.deps, source, target, max_depth=max_depth)


def engine_for_transform(g: TransformationGraph, transform_id: str) -> str | None:
    spec = g.transforms.get(transform_id)
    if spec is None:
        return None
    return str(spec["engine"])
