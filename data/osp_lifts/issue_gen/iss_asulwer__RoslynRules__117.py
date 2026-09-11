"""asulwer/RoslynRules#117 — rule dependency profiler call tree."""

from __future__ import annotations

from collections import deque


class RuleStore:
    def __init__(self) -> None:
        self._rules: dict[str, str | None] = {}
        self._depends: dict[str, list[str]] = {}


def load_rules(
    rules: list[tuple[str, str | None]],
    depends_edges: list[tuple[str, str]],
) -> RuleStore:
    store = RuleStore()
    for rid, parent in rules:
        store._rules[rid] = parent
        store._depends.setdefault(rid, [])
        if parent is not None:
            store._depends.setdefault(parent, []).append(rid)
    for dep, rule in depends_edges:
        if dep in store._rules and rule in store._rules:
            if rule not in store._depends.setdefault(dep, []):
                store._depends[dep].append(rule)
    return store


def rule_ancestors(store: RuleStore, rule_id: str) -> list[str]:
    if rule_id not in store._rules:
        return []
    chain: list[str] = []
    cur: str | None = rule_id
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._rules.get(cur)
    return list(reversed(chain))


def dependent_rules(store: RuleStore, root: str) -> list[str]:
    if root not in store._rules:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in store._depends.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def profile_self_ms(store: RuleStore, rule_id: str, ticks: dict[str, int]) -> int:
    if rule_id not in store._rules:
        return 0
    return ticks.get(rule_id, 0)


def profile_total_ms(store: RuleStore, rule_id: str, ticks: dict[str, int]) -> int:
    total = profile_self_ms(store, rule_id, ticks)
    for dep in dependent_rules(store, rule_id):
        if dep != rule_id:
            total += ticks.get(dep, 0)
    return total
