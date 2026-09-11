"""SzeChunYiu/ccb-testbeam#1594 — Numerical audit claim dependency cascade quarantine."""

from __future__ import annotations


class AuditGraph:
    # Claim parent pointers and children adjacency for dependency-ordered audit.
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._children_of: dict[str, list[str]] = {}
        self._status: dict[str, str] = {}


def load_audit_graph(claims: list[tuple[str, str | None]]) -> AuditGraph:
    g = AuditGraph()
    for name, parent in claims:
        if parent is not None and parent not in g._parent_of:
            raise KeyError("unknown upstream claim")
        g._parent_of[name] = parent
        g._children_of.setdefault(name, [])
        g._status[name] = "pending"
        if parent is not None:
            g._children_of.setdefault(parent, []).append(name)
    return g


def _collect_subtree(store: AuditGraph, root_id: str) -> list[str]:
    stack = [root_id]
    seen: set[str] = set()
    out: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for ch in store._children_of.get(cur, []):
            stack.append(ch)
    return out


def mark_failed(store: AuditGraph, claim_id: str) -> list[str]:
    if claim_id not in store._parent_of:
        raise KeyError("unknown claim")
    to_quarantine = _collect_subtree(store, claim_id)
    changed: list[str] = []
    for cid in to_quarantine:
        if store._status.get(cid) != "quarantined":
            store._status[cid] = "quarantined"
            changed.append(cid)
    return sorted(changed)


def active_claims(store: AuditGraph) -> list[str]:
    return sorted(c for c in store._parent_of if store._status.get(c) != "quarantined")


def upstream_chain(store: AuditGraph, claim: str) -> list[str]:
    if claim not in store._parent_of:
        return []
    chain: list[str] = []
    cur: str | None = claim
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent_of.get(cur)
    return list(reversed(chain))
