"""EffortlessMetrics/cargo-allow#3902 — evidence claim dependency waves."""

from __future__ import annotations

from collections import deque


class EvidenceStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.claims: set[str] = set()


def load_evidence(
    claims: list[str],
    requires: list[tuple[str, str]],
) -> EvidenceStore:
    g = EvidenceStore()
    for c in claims:
        g.claims.add(c)
        g.deps.setdefault(c, [])
    for dst, src in requires:
        if dst in g.claims and src in g.claims and src not in g.deps[dst]:
            g.deps[dst].append(src)
    return g


def evidence_waves(g: EvidenceStore) -> list[list[str]] | None:
    indeg = {c: len(g.deps.get(c, [])) for c in g.claims}
    waves: list[list[str]] = []
    ready = sorted([c for c, d in indeg.items() if d == 0])
    while ready:
        waves.append(ready)
        nxt: list[str] = []
        for base in ready:
            for claim in g.claims:
                if base in g.deps.get(claim, []):
                    indeg[claim] -= 1
                    if indeg[claim] == 0:
                        nxt.append(claim)
        ready = sorted(nxt)
    return waves if sum(len(w) for w in waves) == len(g.claims) else None


def upstream_closure(g: EvidenceStore, claim: str) -> list[str]:
    if claim not in g.claims:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([claim])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(g.deps.get(cur, [])):
            if dep not in seen:
                q.append(dep)
    seen.discard(claim)
    return sorted(seen)
