"""service-lasso/service-lasso#878 — Endpoint propagation through service dependency graph."""

from __future__ import annotations


class RuntimeGraph:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}
        self.endpoints: dict[str, str] = {}
        self.stale: set[str] = set()


def load_runtime_graph(
    services: list[str],
    depends: list[tuple[str, str]],
    endpoints: dict[str, str],
) -> RuntimeGraph:
    g = RuntimeGraph()
    for sid in services:
        g.parent_of[sid] = None
        g.children_of.setdefault(sid, [])
        g.endpoints[sid] = endpoints.get(sid, "")
    for provider, consumer in depends:
        if provider in g.parent_of and consumer in g.parent_of:
            g.parent_of[consumer] = provider
            g.children_of.setdefault(provider, []).append(consumer)
    return g


def _collect_subtree(graph: RuntimeGraph, root_id: str) -> list[str]:
    stack = [root_id]
    seen: set[str] = set()
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in graph.children_of.get(cur, []):
            stack.append(ch)
    return out


def impacted_consumers(graph: RuntimeGraph, provider_id: str) -> list[str]:
    if provider_id not in graph.parent_of:
        return []
    return sorted(
        sid
        for sid in _collect_subtree(graph, provider_id)
        if sid != provider_id
    )


def propagate_endpoint(
    graph: RuntimeGraph,
    provider_id: str,
    new_value: str,
) -> list[str]:
    if provider_id not in graph.parent_of:
        raise KeyError("unknown provider")
    graph.endpoints[provider_id] = new_value
    rematerialized: list[str] = [provider_id]
    for sid in impacted_consumers(graph, provider_id):
        graph.endpoints[sid] = new_value
        graph.stale.add(sid)
        rematerialized.append(sid)
    return sorted(rematerialized)


def active_endpoints(graph: RuntimeGraph) -> dict[str, str]:
    return {k: graph.endpoints[k] for k in sorted(graph.parent_of)}
