"""TinyChain-Inc/client#37 — class-aware annotations, bounded mutations, graph queries.

Hand-rolled extends chain resolution, relates adjacency + deque BFS reach,
and depth-bounded writable-instance sweep (ORM mutation authority surface).
"""

from __future__ import annotations

from collections import deque


class OrmSchema:
    def __init__(self) -> None:
        self.classes: dict[str, str] = {}
        self.extends: dict[str, str] = {}
        self.members: dict[str, dict[str, str]] = {}
        self.instances: dict[str, str] = {}
        self.relates: dict[str, list[str]] = {}
        self.max_depth: int = 4


def load_schema(
    classes: list[tuple[str, str]],
    extends: list[tuple[str, str]],
    members: dict[str, dict[str, str]],
    instances: list[tuple[str, str]],
    relates: list[tuple[str, str]],
    max_depth: int = 4,
) -> OrmSchema:
    g = OrmSchema()
    for cid, name in classes:
        g.classes[cid] = name
        g.members.setdefault(cid, {})
    for child, parent in extends:
        if child in g.classes and parent in g.classes:
            g.extends[child] = parent
    for cid, spec in members.items():
        if cid in g.classes:
            g.members[cid] = dict(spec)
    for iid, class_id in instances:
        if class_id in g.classes:
            g.instances[iid] = class_id
            g.relates.setdefault(iid, [])
    for src, tgt in relates:
        if src in g.instances and tgt in g.instances:
            g.relates.setdefault(src, []).append(tgt)
    g.max_depth = max_depth
    return g


def _effective_members(g: OrmSchema, class_id: str) -> dict[str, str]:
    if class_id not in g.classes:
        return {}
    merged: dict[str, str] = {}
    seen: set[str] = set()
    chain: list[str] = []
    cur: str | None = class_id
    while cur and cur not in seen:
        seen.add(cur)
        chain.append(cur)
        cur = g.extends.get(cur)
    for cid in reversed(chain):
        merged.update(g.members.get(cid, {}))
    return merged


def annotated_fields(g: OrmSchema, class_id: str) -> list[str]:
    eff = _effective_members(g, class_id)
    return sorted(k for k, v in eff.items() if v != "unsupported")


def _instance_writable(g: OrmSchema, iid: str) -> bool:
    cid = g.instances.get(iid)
    if cid is None:
        return False
    return any(v == "writable" for v in _effective_members(g, cid).values())


def query_reach(g: OrmSchema, start: str) -> list[str]:
    if start not in g.instances:
        return []
    seen: set[str] = set()
    work: deque[str] = deque([start])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in g.relates.get(cur, []):
            if nxt in g.instances:
                work.append(nxt)
    return sorted(hits)


def mutate_bounded(g: OrmSchema, root_id: str, depth: int) -> list[str]:
    if root_id not in g.instances:
        return []
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque([(root_id, 0)])
    hits: list[str] = []
    while work:
        cur, dist = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if dist > depth:
            continue
        if _instance_writable(g, cur):
            hits.append(cur)
        if dist < depth:
            for nxt in g.relates.get(cur, []):
                if nxt in g.instances and nxt not in seen:
                    work.append((nxt, dist + 1))
    return sorted(hits)
