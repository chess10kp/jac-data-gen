"""EffortlessMetrics/perl-lsp-swarm#8965 — cut generated-member consumers over to canonical adapter facts."""

from __future__ import annotations

from collections import deque


class MooModel:
    def __init__(self) -> None:
        self.classes: set[str] = set()
        self.parent: dict[str, list[str]] = {}
        self.roles: dict[str, list[str]] = {}
        self.canonical: dict[str, set[str]] = {}
        self.producers: dict[tuple[str, str], list[str]] = {}


def load_moo_model(
    classes: list[str],
    extends: list[tuple[str, str]],
    with_roles: list[tuple[str, str]],
    canonical_facts: list[tuple[str, str]],
    duplicate_producers: list[tuple[str, str, str]],
) -> MooModel:
    m = MooModel()
    for cls in classes:
        m.classes.add(cls)
        m.roles.setdefault(cls, [])
        m.canonical.setdefault(cls, set())
    for child, par in extends:
        if child in m.classes and par in m.classes:
            m.parent.setdefault(child, [])
            if par not in m.parent[child]:
                m.parent[child].append(par)
    for cls, role in with_roles:
        if cls in m.classes and role in m.classes:
            m.roles[cls].append(role)
    for cls, fact in canonical_facts:
        if cls in m.classes:
            m.canonical[cls].add(fact)
    for consumer, fact, producer in duplicate_producers:
        key = (consumer, fact)
        m.producers.setdefault(key, [])
        if producer not in m.producers[key]:
            m.producers[key].append(producer)
    return m


def upstream_lineage(m: MooModel, class_id: str) -> list[str]:
    if class_id not in m.classes:
        return []
    out: list[str] = []
    seen: set[str] = {class_id}
    cur_list = m.parent.get(class_id, [])
    cur = cur_list[0] if cur_list else None
    while cur is not None and cur not in seen:
        seen.add(cur)
        out.append(cur)
        nxt = m.parent.get(cur, [])
        cur = nxt[0] if nxt else None
    return out
    return out


def lineage_bfs_reach(m: MooModel, start: str, max_depth: int = 12) -> list[str]:
    if start not in m.classes:
        return []
    seen: set[str] = {start}
    order: list[str] = []
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        node, depth = q.popleft()
        if node != start:
            order.append(node)
        if depth >= max_depth:
            continue
        nbrs: list[str] = []
        for par in m.parent.get(node, []):
            if par in m.classes:
                nbrs.append(par)
        nbrs.extend(m.roles.get(node, []))
        for nb in sorted(nbrs):
            if nb not in seen:
                seen.add(nb)
                q.append((nb, depth + 1))
    return order


def fact_holder_paths(
    m: MooModel,
    consumer: str,
    fact_id: str,
    max_depth: int = 8,
) -> list[list[str]]:
    if consumer not in m.classes:
        return []
    out: list[list[str]] = []
    stack: list[tuple[str, list[str]]] = [(consumer, [consumer])]
    while stack:
        node, trail = stack.pop()
        if fact_id in m.canonical.get(node, set()):
            out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        on_trail = set(trail)
        nbrs: list[str] = []
        for par in m.parent.get(node, []):
            if par in m.classes:
                nbrs.append(par)
        nbrs.extend(m.roles.get(node, []))
        for nb in sorted(nbrs):
            if nb not in on_trail:
                stack.append((nb, trail + [nb]))
    return sorted(out)


def cutover_route(
    *,
    has_canonical: bool,
    shadow_ok: bool,
    freshness_ok: bool,
    semantic_ok: bool,
    provider_ready: bool,
) -> str:
    if not has_canonical:
        return "refusal"
    if shadow_ok and freshness_ok and semantic_ok and provider_ready:
        return "canonical"
    return "fallback"


def duplicate_path_inventory(m: MooModel, consumer: str, fact_id: str) -> dict[str, str]:
    producers = sorted(m.producers.get((consumer, fact_id), []))
    if not producers:
        return {}
    holders = fact_holder_paths(m, consumer, fact_id)
    if not holders:
        inv: dict[str, str] = {}
        for p in producers:
            if p.startswith("test_"):
                inv[p] = "retained_standalone_test_only"
            else:
                inv[p] = "retained_bounded_fallback_for_named_unsupported_form"
        return inv
    owner = holders[0][-1]
    canon_id = f"canonical:{owner}"
    inv: dict[str, str] = {}
    for p in producers:
        if p == canon_id:
            inv[p] = "transferred_to_canonical_owner"
        elif p.startswith("test_"):
            inv[p] = "retained_standalone_test_only"
        else:
            inv[p] = "removed_after_cutover"
    return inv
