"""acryldata/mcp-server-datahub#152 — MCP lineage tools inherit per-call telemetry stall."""

from __future__ import annotations

from collections import deque

TELEMETRY_STALL_MS = 54000
FAST_QUERY_MS = 90


class LineageRegistry:
    def __init__(self, *, telemetry_enabled: bool = True) -> None:
        self.datasets: dict[str, dict[str, int | str]] = {}
        self.upstream: dict[str, list[str]] = {}
        self.downstream: dict[str, list[str]] = {}
        self.fields: dict[str, list[str]] = {}
        self.telemetry_enabled = telemetry_enabled
        self.call_count = 0


def load_lineage_registry(
    datasets: list[tuple[str, str, int]],
    edges: list[tuple[str, str]],
    schema: list[tuple[str, list[str]]],
    *,
    telemetry_enabled: bool = True,
) -> LineageRegistry:
    reg = LineageRegistry(telemetry_enabled=telemetry_enabled)
    for urn, layer, updated_at in datasets:
        reg.datasets[urn] = {"layer": layer, "updated_at": updated_at}
        reg.upstream[urn] = []
        reg.downstream[urn] = []
    for src, tgt in edges:
        if src not in reg.datasets or tgt not in reg.datasets:
            continue
        reg.downstream[src].append(tgt)
        reg.upstream[tgt].append(src)
    for urn in reg.upstream:
        reg.upstream[urn].sort()
    for urn in reg.downstream:
        reg.downstream[urn].sort()
    for urn, flds in schema:
        reg.fields[urn] = sorted(flds)
    return reg


def _account_call(reg: LineageRegistry) -> int:
    reg.call_count += 1
    if reg.telemetry_enabled:
        return TELEMETRY_STALL_MS + FAST_QUERY_MS
    return FAST_QUERY_MS


def _bfs_reach(adj: dict[str, list[str]], start: str, known: set[str]) -> list[str]:
    if start not in known:
        return []
    seen: set[str] = {start}
    hits: list[str] = []
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                hits.append(nxt)
                queue.append(nxt)
    return sorted(hits)


def _lineage_paths(
    reg: LineageRegistry,
    source: str,
    target: str,
    *,
    max_depth: int,
) -> list[list[str]]:
    if source not in reg.datasets or target not in reg.datasets:
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
        for nxt in sorted(reg.upstream.get(node, [])):
            walk(nxt, trail + [nxt])

    walk(source, [source])
    return sorted(paths)


def get_lineage(
    reg: LineageRegistry,
    urn: str,
    direction: str = "upstream",
) -> list[str]:
    _account_call(reg)
    if urn not in reg.datasets:
        return []
    adj = reg.upstream if direction == "upstream" else reg.downstream
    return _bfs_reach(adj, urn, set(reg.datasets))


def list_schema_fields(reg: LineageRegistry, urn: str) -> list[str]:
    _account_call(reg)
    if urn not in reg.datasets:
        return []
    return list(reg.fields.get(urn, []))


def get_lineage_paths_between(
    reg: LineageRegistry,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    _account_call(reg)
    return _lineage_paths(reg, source, target, max_depth=max_depth)


def per_call_latency_ms(reg: LineageRegistry, tool: str) -> int:
    return _account_call(reg)


def bulk_paths_stall_ms(
    reg: LineageRegistry,
    pairs: list[tuple[str, str]],
) -> int:
    total = 0
    for src, tgt in pairs:
        total += _account_call(reg)
        _lineage_paths(reg, src, tgt, max_depth=12)
    return total
