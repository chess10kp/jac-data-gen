"""voltrevo/wac#8 — content-addressed nominal type identity.

Hand-rolled type spec registry, recursive canonical digest over ref edges,
and deque BFS dependency closure with visited-set cycle termination.
"""

from __future__ import annotations

from collections import deque
from hashlib import sha256


class TypeStore:
    def __init__(self) -> None:
        self._specs: dict[str, dict] = {}
        self._refs: list[tuple[str, str, str]] = []


def load_types(
    specs: dict[str, dict],
    refs: list[tuple[str, str, str]],
) -> TypeStore:
    g = TypeStore()
    g._specs = {k: dict(v) for k, v in specs.items()}
    g._refs = list(refs)
    return g


def _canon(g: TypeStore, tid: str, visiting: set[str]) -> str:
    if tid in visiting:
        return "<cycle>"
    spec = g._specs.get(tid)
    if spec is None:
        return ""
    visiting.add(tid)
    parts = [spec.get("kind", ""), spec.get("name", ""), repr(spec.get("fields", []))]
    for src, slot, tgt in g._refs:
        if src == tid:
            parts.append(f"{slot}:{_canon(g, tgt, visiting)}")
    visiting.discard(tid)
    return "|".join(parts)


def type_digest(g: TypeStore, tid: str) -> str:
    if tid not in g._specs:
        return ""
    return sha256(_canon(g, tid, set()).encode()).hexdigest()[:16]


def same_identity(g: TypeStore, a: str, b: str) -> bool:
    if a not in g._specs or b not in g._specs:
        return False
    return type_digest(g, a) == type_digest(g, b)


def dependency_closure(g: TypeStore, tid: str) -> list[str]:
    if tid not in g._specs:
        return []
    adj: dict[str, list[str]] = {k: [] for k in g._specs}
    for src, _slot, tgt in g._refs:
        if src in adj and tgt in g._specs:
            adj[src].append(tgt)
    seen: set[str] = set()
    work: deque[str] = deque([tid])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != tid:
            hits.append(cur)
        for nxt in adj.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    return sorted(hits)
