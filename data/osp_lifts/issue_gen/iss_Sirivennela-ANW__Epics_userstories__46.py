"""Sirivennela-ANW/Epics_userstories#46 — Data lineage visualization and impact analysis."""

from __future__ import annotations

from collections import deque


class LineageCatalog:
    def __init__(self) -> None:
        self.datasets: dict[str, dict] = {}
        self.upstream: dict[str, list[str]] = {}
        self.downstream: dict[str, list[str]] = {}
        self.edge_meta: dict[tuple[str, str], dict] = {}


def load_lineage_catalog(
    datasets: list[tuple[str, str, int]],
    transforms: list[tuple[str, str, str, float, int]],
) -> LineageCatalog:
    cat = LineageCatalog()
    for ds_id, layer, volume in datasets:
        cat.datasets[ds_id] = {"layer": layer, "volume": volume}
        cat.upstream[ds_id] = []
        cat.downstream[ds_id] = []
    for src, tgt, rule, quality, proc_ms in transforms:
        if src not in cat.datasets or tgt not in cat.datasets:
            continue
        if src not in cat.upstream[tgt]:
            cat.upstream[tgt].append(src)
        if tgt not in cat.downstream[src]:
            cat.downstream[src].append(tgt)
        cat.edge_meta[(src, tgt)] = {
            "rule": rule,
            "quality": quality,
            "proc_ms": proc_ms,
        }
    for ds_id in cat.upstream:
        cat.upstream[ds_id].sort()
    for ds_id in cat.downstream:
        cat.downstream[ds_id].sort()
    return cat


def _bfs_closure(adj: dict[str, list[str]], start: str, known: set[str]) -> list[str]:
    if start not in known:
        return []
    seen: set[str] = {start}
    hits: list[str] = []
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                hits.append(nxt)
                q.append(nxt)
    return sorted(hits)


def origin_lineage(cat: LineageCatalog, dataset_id: str) -> list[str]:
    return _bfs_closure(cat.upstream, dataset_id, set(cat.datasets))


def impact_lineage(cat: LineageCatalog, dataset_id: str) -> list[str]:
    return _bfs_closure(cat.downstream, dataset_id, set(cat.datasets))


def lineage_paths(
    cat: LineageCatalog,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in cat.datasets or target not in cat.datasets:
        return []
    paths: list[list[str]] = []

    def walk(node: str, trail: list[str]) -> None:
        if node in trail[:-1]:
            return
        if node == target:
            paths.append(list(trail))
            return
        if len(trail) >= max_depth:
            return
        for nxt in sorted(cat.upstream.get(node, [])):
            walk(nxt, trail + [nxt])

    walk(source, [source])
    return sorted(paths)


def transformation_rules(cat: LineageCatalog, dataset_id: str) -> list[str]:
    if dataset_id not in cat.datasets:
        return []
    rules: list[str] = []
    for src in cat.upstream.get(dataset_id, []):
        meta = cat.edge_meta.get((src, dataset_id))
        if meta is not None:
            rules.append(str(meta["rule"]))
    return sorted(rules)


def downstream_volume(cat: LineageCatalog, dataset_id: str) -> int:
    total = 0
    for ds_id in impact_lineage(cat, dataset_id):
        total += int(cat.datasets[ds_id]["volume"])
    return total
