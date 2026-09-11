"""Shared-Reality-Lab/IMAGE-server#1020 — orchestrator output-vs-service dependency resolution."""

from __future__ import annotations

from collections import deque


class OrchestratorRegistry:
    def __init__(self) -> None:
        self.services: dict[str, dict] = {}
        self._edges: dict[str, list[str]] = {}
        self._built: bool = False


def create_registry() -> OrchestratorRegistry:
    return OrchestratorRegistry()


def register_service(
    reg: OrchestratorRegistry,
    name: str,
    outputs: list[str] | None = None,
    required: list[str] | None = None,
    optional: list[str] | None = None,
    active: bool = True,
) -> None:
    reg.services[name] = {
        "outputs": set(outputs or []),
        "required": list(required or []),
        "optional": list(optional or []),
        "active": active,
    }
    reg._built = False


def _provider_index(reg: OrchestratorRegistry) -> dict[str, list[str]]:
    idx: dict[str, list[str]] = {}
    for svc, meta in sorted(reg.services.items()):
        if not meta["active"]:
            continue
        for out in sorted(meta["outputs"]):
            idx.setdefault(out, [])
            if svc not in idx[out]:
                idx[out].append(svc)
    return {out: sorted(providers) for out, providers in idx.items()}


def _resolve_label(
    reg: OrchestratorRegistry,
    label: str,
    providers: dict[str, list[str]],
) -> str | None:
    meta = reg.services.get(label)
    if meta is not None and meta["active"]:
        return label
    choices = providers.get(label, [])
    if choices:
        return choices[0]
    return None


def build_dependency_graph(reg: OrchestratorRegistry) -> dict[str, list[str]]:
    providers = _provider_index(reg)
    adj: dict[str, list[str]] = {}
    for svc, meta in reg.services.items():
        if not meta["active"]:
            continue
        prereqs: list[str] = []
        for label in meta["required"]:
            resolved = _resolve_label(reg, label, providers)
            if resolved is not None and resolved != svc and resolved not in prereqs:
                prereqs.append(resolved)
        adj[svc] = sorted(prereqs)
    reg._edges = adj
    reg._built = True
    return adj


def output_providers(reg: OrchestratorRegistry, output_id: str) -> list[str]:
    return list(_provider_index(reg).get(output_id, []))


def execution_order(reg: OrchestratorRegistry) -> list[str] | None:
    adj = reg._edges if reg._built else build_dependency_graph(reg)
    indeg = {svc: len(deps) for svc, deps in adj.items()}
    rev: dict[str, list[str]] = {svc: [] for svc in adj}
    for svc, deps in adj.items():
        for dep in deps:
            rev[dep].append(svc)
    q: deque[str] = deque(sorted(svc for svc, deg in indeg.items() if deg == 0))
    order: list[str] = []
    while q:
        cur = q.popleft()
        order.append(cur)
        for nxt in sorted(rev.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
        q = deque(sorted(q))
    if len(order) != len(adj):
        return None
    return order


def upstream_services(reg: OrchestratorRegistry, service: str) -> list[str]:
    adj = reg._edges if reg._built else build_dependency_graph(reg)
    if service not in adj:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(adj.get(service, []))
    hits: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != service:
            hits.add(cur)
        for up in adj.get(cur, []):
            if up not in seen:
                q.append(up)
    return sorted(hits)


def has_execution_cycle(reg: OrchestratorRegistry) -> bool:
    return execution_order(reg) is None
