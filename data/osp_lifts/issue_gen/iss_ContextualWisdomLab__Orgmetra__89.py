"""ContextualWisdomLab/Orgmetra#89 — required gate closure on develop ruleset."""

from __future__ import annotations

from collections import deque


class RulesetStore:
    def __init__(self) -> None:
        self.deps: dict[str, list[str]] = {}
        self.gates: set[str] = set()


def load_ruleset(
    gates: list[str],
    requires: list[tuple[str, str]],
) -> RulesetStore:
    r = RulesetStore()
    for g in gates:
        r.gates.add(g)
        r.deps.setdefault(g, [])
    for gate, prereq in requires:
        if gate in r.gates and prereq in r.gates:
            r.deps[gate].append(prereq)
    return r


def required_closure(store: RulesetStore, gate: str) -> list[str]:
    if gate not in store.gates:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([gate])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for dep in sorted(store.deps.get(cur, [])):
            if dep not in seen:
                q.append(dep)
    seen.discard(gate)
    return sorted(seen)


def merge_blockers(store: RulesetStore, failed: list[str]) -> list[str]:
    blocked: set[str] = set()
    for gate in store.gates:
        need = required_closure(store, gate) + [gate]
        if any(req in failed for req in need):
            blocked.add(gate)
    return sorted(blocked)
