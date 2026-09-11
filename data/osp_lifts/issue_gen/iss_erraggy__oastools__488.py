"""erraggy/oastools#488 — generated DeepCopy is not cycle safe.

Hand-rolled schema pointer graph, recursive deep_copy with a copied-id map
(DeepCopyInto visited threading), and deque BFS ref_closure with a visited set
(mirrors SchemaRewriter rewrite traversal).
"""

from __future__ import annotations

from collections import deque


class SchemaStore:
    """Fresh handle per test; nodes and ref triples live here."""

    def __init__(self) -> None:
        self._nodes: dict[str, dict[str, str]] = {}
        self._refs: list[tuple[str, str, str]] = []


def load_schema(
    nodes: list[tuple[str, str]],
    refs: list[tuple[str, str, str]],
) -> SchemaStore:
    g = SchemaStore()
    for sid, kind in nodes:
        g._nodes[sid] = {"kind": kind}
    g._refs = list(refs)
    return g


def deep_copy(g: SchemaStore, root_id: str) -> dict:
    # Cycle-safe DeepCopyInto: register in copied map before descending.
    if root_id not in g._nodes:
        return {}
    copied: dict[str, dict] = {}

    def copy_into(src_id: str) -> dict:
        if src_id in copied:
            return copied[src_id]
        spec = g._nodes[src_id]
        out: dict = {"kind": spec["kind"], "props": {}}
        copied[src_id] = out
        for s, field, tgt in g._refs:
            if s == src_id:
                out["props"][field] = copy_into(tgt)
        return out

    return copy_into(root_id)


def ref_closure(g: SchemaStore, root_id: str) -> list[str]:
    # Rewriter-style reachability: visited set terminates pointer cycles.
    if root_id not in g._nodes:
        return []
    adj: dict[str, list[str]] = {sid: [] for sid in g._nodes}
    for src, _field, tgt in g._refs:
        if src in adj and tgt in g._nodes:
            adj[src].append(tgt)
    seen: set[str] = set()
    work: deque[str] = deque([root_id])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != root_id:
            hits.append(cur)
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    return sorted(hits)
