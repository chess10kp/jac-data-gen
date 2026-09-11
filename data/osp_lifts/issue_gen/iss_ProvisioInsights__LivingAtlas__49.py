"""ProvisioInsights/LivingAtlas#49 — typed Praxis knowledge APIs and canonical export/import."""

from __future__ import annotations

from collections import deque


def make_knowledge_graph(
    entities: list[dict],
    facts: list[dict],
    depends: list[tuple[str, str]],
    parents: list[tuple[str, str]],
) -> dict:
    graph: dict = {
        "entities": {e["id"]: dict(e) for e in entities},
        "facts": {},
        "dep_fwd": {},
        "dep_rev": {},
        "parent": {},
        "children": {},
    }
    for fact in facts:
        eid = fact["entity_id"]
        graph["facts"].setdefault(eid, []).append(dict(fact))
    for dependent, dependency in depends:
        graph["dep_fwd"].setdefault(dependent, [])
        if dependency not in graph["dep_fwd"][dependent]:
            graph["dep_fwd"][dependent].append(dependency)
        graph["dep_rev"].setdefault(dependency, [])
        if dependent not in graph["dep_rev"][dependency]:
            graph["dep_rev"][dependency].append(dependent)
    for child, parent in parents:
        graph["parent"][child] = parent
        graph["children"].setdefault(parent, [])
        if child not in graph["children"][parent]:
            graph["children"][parent].append(child)
    return graph


def get_entity(graph: dict, entity_id: str) -> dict | None:
    ent = graph["entities"].get(entity_id)
    if ent is None:
        return None
    return dict(ent)


def query_facts(graph: dict, entity_id: str) -> list[dict]:
    rows = graph["facts"].get(entity_id, [])
    return sorted(rows, key=lambda row: (row["key"], row.get("valid_at", "")))


def upstream_dependencies(graph: dict, entity_id: str, max_hops: int = 8) -> list[str]:
    if entity_id not in graph["entities"]:
        return []
    seen: set[str] = set()
    q: deque[tuple[str, int]] = deque([(entity_id, 0)])
    hits: list[str] = []
    while q:
        cur, depth = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != entity_id:
            hits.append(cur)
        if depth >= max_hops:
            continue
        for dep in sorted(graph["dep_fwd"].get(cur, [])):
            if dep not in seen:
                q.append((dep, depth + 1))
    return sorted(hits)


def downstream_dependents(graph: dict, entity_id: str, max_hops: int = 8) -> list[str]:
    if entity_id not in graph["entities"]:
        return []
    seen: set[str] = set()
    q: deque[tuple[str, int]] = deque([(entity_id, 0)])
    hits: list[str] = []
    while q:
        cur, depth = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != entity_id:
            hits.append(cur)
        if depth >= max_hops:
            continue
        for dep in sorted(graph["dep_rev"].get(cur, [])):
            if dep not in seen:
                q.append((dep, depth + 1))
    return sorted(hits)


def depends_path(graph: dict, src: str, dst: str) -> list[str]:
    if src not in graph["entities"] or dst not in graph["entities"]:
        return []
    parent: dict[str, str | None] = {src: None}
    q: deque[str] = deque([src])
    while q:
        cur = q.popleft()
        if cur == dst:
            trail: list[str] = []
            node: str | None = dst
            while node is not None:
                trail.append(node)
                node = parent[node]
            return list(reversed(trail))
        for nxt in sorted(graph["dep_fwd"].get(cur, [])):
            if nxt not in parent:
                parent[nxt] = cur
                q.append(nxt)
    return []


def lineage_to_root(graph: dict, entity_id: str) -> list[str]:
    if entity_id not in graph["entities"]:
        return []
    chain: list[str] = [entity_id]
    claimed: set[str] = {entity_id}
    cur = entity_id
    while cur in graph["parent"]:
        par = graph["parent"][cur]
        if par in claimed:
            break
        claimed.add(par)
        chain.append(par)
        cur = par
    return chain


def entity_counts(graph: dict) -> dict[str, int]:
    active = sum(1 for ent in graph["entities"].values() if not ent.get("tombstone"))
    tombstone = sum(1 for ent in graph["entities"].values() if ent.get("tombstone"))
    return {"active": active, "tombstone": tombstone, "total": len(graph["entities"])}


def canonical_export(graph: dict) -> dict:
    entities = sorted(graph["entities"].values(), key=lambda ent: ent["id"])
    facts_out: list[dict] = []
    for eid in sorted(graph["facts"].keys()):
        for fact in sorted(
            graph["facts"][eid],
            key=lambda row: (row["key"], row.get("valid_at", "")),
        ):
            facts_out.append(dict(fact))
    depends_out = sorted(
        (dependent, dependency)
        for dependent, deps in graph["dep_fwd"].items()
        for dependency in deps
    )
    parents_out = sorted(graph["parent"].items())
    return {
        "version": "1",
        "entities": [dict(ent) for ent in entities],
        "facts": facts_out,
        "depends": depends_out,
        "parents": parents_out,
    }


def canonical_import(bundle: dict) -> dict:
    if bundle.get("version") != "1":
        raise ValueError("unsupported export version")
    depends = [(a, b) for a, b in bundle["depends"]]
    parents = [(child, parent) for child, parent in bundle["parents"]]
    return make_knowledge_graph(
        bundle["entities"],
        bundle["facts"],
        depends,
        parents,
    )
