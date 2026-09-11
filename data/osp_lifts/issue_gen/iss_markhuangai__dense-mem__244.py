"""Ontology-guided traversal, hierarchy, and one-layer rules. Source: markhuangai/dense-mem#244."""

from __future__ import annotations

from collections import deque

Rule = tuple[list[tuple[str, str, str]], tuple[str, str, str]]


def _rel_adj(edges: list[tuple[str, str]]) -> dict[str, list[str]]:
    adj: dict[str, list[str]] = {}
    for src, dst in sorted(edges):
        adj.setdefault(src, []).append(dst)
    return adj


def guided_traversal(
    start: str,
    edges: list[tuple[str, str]],
    allowed: set[str],
) -> list[str]:
    # Policy-gated bounded graph read with deterministic neighbor order.
    if start not in allowed:
        return []
    adj = _rel_adj(edges)
    seen: set[str] = set()
    order: list[str] = []
    q: deque[str] = deque([start])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        order.append(node)
        for nxt in adj.get(node, []):
            if nxt in allowed and nxt not in seen:
                q.append(nxt)
    return order


def _hierarchy_is_dag(parent_edges: list[tuple[str, str]]) -> bool:
    adj: dict[str, list[str]] = {}
    nodes: set[str] = set()
    for child, par in parent_edges:
        adj.setdefault(child, []).append(par)
        nodes.add(child)
        nodes.add(par)
    color: dict[str, int] = {n: 0 for n in nodes}

    def dfs(u: str) -> bool:
        color[u] = 1
        for v in adj.get(u, []):
            if color.get(v, 0) == 1:
                return False
            if color.get(v, 0) == 0 and not dfs(v):
                return False
        color[u] = 2
        return True

    for n in nodes:
        if color[n] == 0 and not dfs(n):
            return False
    return True


def hierarchy_closure(
    root: str,
    parent_edges: list[tuple[str, str]],
) -> list[str]:
    # Subclass inheritance closure; reject hierarchy cycles before walking.
    if not _hierarchy_is_dag(parent_edges):
        raise ValueError("hierarchy cycle")
    parents: dict[str, list[str]] = {}
    for child, par in sorted(parent_edges):
        parents.setdefault(child, []).append(par)
    seen: set[str] = set()
    order: list[str] = []
    q: deque[str] = deque([root])
    while q:
        node = q.popleft()
        if node in seen:
            continue
        seen.add(node)
        order.append(node)
        for par in parents.get(node, []):
            if par not in seen:
                q.append(par)
    return order if order else [root]


def _bind_one(
    atom: tuple[str, str, str],
    fact: tuple[str, str, str],
    bind: dict[str, str],
) -> dict[str, str] | None:
    s, p, o = atom
    fs, fp, fo = fact
    if p != fp:
        return None
    out = dict(bind)
    if s.startswith("?"):
        if s in out and out[s] != fs:
            return None
        out[s] = fs
    elif s != fs:
        return None
    if o.startswith("?"):
        if o in out and out[o] != fo:
            return None
        out[o] = fo
    elif o != fo:
        return None
    return out


def _instantiate(
    atom: tuple[str, str, str], bind: dict[str, str]
) -> tuple[str, str, str]:
    s, p, o = atom
    if s.startswith("?"):
        s = bind[s]
    if o.startswith("?"):
        o = bind[o]
    return (s, p, o)


def apply_rules(
    facts: list[tuple[str, str, str]],
    rules: list[Rule],
) -> list[tuple[str, str, str]]:
    # One rule layer only; derived heads cannot re-trigger rules.
    derived: list[tuple[str, str, str]] = []
    for body, head in rules:
        if len(body) == 1:
            for fact in facts:
                binding = _bind_one(body[0], fact, {})
                if binding is None:
                    continue
                got = _instantiate(head, binding)
                if got not in facts and got not in derived:
                    derived.append(got)
        elif len(body) == 2:
            for f1 in facts:
                b1 = _bind_one(body[0], f1, {})
                if b1 is None:
                    continue
                for f2 in facts:
                    b2 = _bind_one(body[1], f2, b1)
                    if b2 is None:
                        continue
                    got = _instantiate(head, b2)
                    if got not in facts and got not in derived:
                        derived.append(got)
    return sorted(derived)
