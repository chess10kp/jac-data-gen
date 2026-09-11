"""EffortlessMetrics/perl-lsp-swarm#10074 — bounded native syntax artifact builder.

Hand-rolled field-reference adjacency, deque reachability, and iterative
arena emission with a node cap (projection limit).
"""

from __future__ import annotations

from collections import deque


class SnapshotStore:
    def __init__(self) -> None:
        self.schema_id: str = ""
        self.root_nid: str = ""
        self.max_nodes: int = 256
        self._nodes: dict[str, dict] = {}
        self._refs: dict[str, list[tuple[str, str]]] = {}


def load_snapshot(
    nodes: dict[str, dict],
    root_nid: str,
    schema_id: str,
    max_nodes: int = 256,
) -> SnapshotStore:
    g = SnapshotStore()
    g.schema_id = schema_id
    g.root_nid = root_nid
    g.max_nodes = max_nodes
    g._nodes = {nid: dict(spec) for nid, spec in nodes.items()}
    g._refs = {}
    for nid, spec in g._nodes.items():
        refs: list[tuple[str, str]] = []
        for slot, tgt in spec.get("refs", []):
            refs.append((str(slot), str(tgt)))
        g._refs[nid] = sorted(refs, key=lambda p: p[0])
    return g


def _fwd_adj(g: SnapshotStore) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {nid: [] for nid in g._nodes}
    for src, pairs in g._refs.items():
        for _slot, dst in pairs:
            if dst in adj:
                adj[src].append(dst)
    return adj


def field_reachable(g: SnapshotStore, start_nid: str) -> list[str]:
    if start_nid not in g._nodes:
        return []
    adj = _fwd_adj(g)
    seen: set[str] = set()
    work: deque[str] = deque([start_nid])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != start_nid:
            hits.append(cur)
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    return sorted(hits)


def build_native_artifact(g: SnapshotStore) -> tuple[dict | None, str]:
    if g.root_nid not in g._nodes:
        return None, "invalid_snapshot"

    ordered: list[str] = []
    seen: set[str] = set()
    work: deque[str] = deque([g.root_nid])

    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        if len(ordered) >= g.max_nodes:
            return None, "projection_limit_exceeded"
        seen.add(cur)
        ordered.append(cur)
        for slot, tgt in g._refs.get(cur, []):
            if tgt in g._nodes and tgt not in seen:
                work.append(tgt)

    idx_map = {nid: i for i, nid in enumerate(ordered)}
    table: list[dict] = []
    for i, nid in enumerate(ordered):
        spec = g._nodes[nid]
        fields: list[tuple[str, int]] = []
        for slot, tgt in g._refs.get(nid, []):
            if tgt in idx_map:
                fields.append((slot, idx_map[tgt]))
        table.append(
            {
                "local_id": i,
                "kind": spec.get("kind", ""),
                "start": spec.get("start", 0),
                "end": spec.get("end", 0),
                "fields": fields,
            }
        )

    artifact = {
        "schema_id": g.schema_id,
        "root": idx_map[g.root_nid],
        "nodes": table,
        "disposition": "complete",
    }
    return artifact, "complete"
