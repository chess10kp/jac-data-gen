"""MIT-LCP/mimic-code#2158 -- dependency graph for MIMIC concepts."""

from __future__ import annotations

from collections import deque

class ConceptGraph:
    def __init__(self) -> None:
        self.concepts: set[str] = set()
        self.adj: dict[str, list[str]] = {}  # dependency -> dependent
        self.rev: dict[str, list[str]] = {}  # dependent -> dependencies
        self.in_degree: dict[str, int] = {}

def make_graph() -> ConceptGraph:
    return ConceptGraph()

def add_concept(g: ConceptGraph, name: str) -> None:
    if name in g.concepts:
        raise ValueError("duplicate concept")
    g.concepts.add(name)
    g.adj.setdefault(name, [])
    g.rev.setdefault(name, [])
    g.in_degree.setdefault(name, 0)

def add_dependency(g: ConceptGraph, concept: str, depends_on: str) -> None:
    # concept depends_on prerequisite
    if concept not in g.concepts or depends_on not in g.concepts:
        raise KeyError("unknown concept")
    if concept == depends_on:
        raise ValueError("self edge")
    if concept in g.adj.get(depends_on, []):
        raise ValueError("duplicate edge")
    # cycle guard via BFS
    q: deque[str] = deque([concept])
    seen: set[str] = set()
    while q:
        cur = q.popleft()
        if cur == depends_on:
            raise ValueError("cycle")
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.adj.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    g.adj[depends_on].append(concept)
    g.rev[concept].append(depends_on)
    g.in_degree[concept] = g.in_degree.get(concept, 0) + 1

def topological_order(g: ConceptGraph) -> list[str] | None:
    # Kahn's algorithm with deterministic sorted queue (hand-rolled queue walk)
    indeg = dict(g.in_degree)
    for c in g.concepts:
        indeg.setdefault(c, 0)
    q: deque[str] = deque(sorted([c for c, d in indeg.items() if d == 0]))
    order: list[str] = []
    while q:
        cur = q.popleft()
        order.append(cur)
        for nxt in sorted(g.adj.get(cur, [])):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                q.append(nxt)
        # keep deterministic: sort queue after insertion (multiset stable)
        q = deque(sorted(q))
    if len(order) != len(g.concepts):
        return None
    return order

def find_cycle(g: ConceptGraph) -> list[str] | None:
    # DFS to find cycle path
    visited: set[str] = set()
    stack: list[str] = []
    onstack: set[str] = set()
    def dfs(node: str) -> list[str] | None:
        visited.add(node)
        stack.append(node)
        onstack.add(node)
        for nxt in g.adj.get(node, []):
            if nxt not in visited:
                res = dfs(nxt)
                if res:
                    return res
            elif nxt in onstack:
                idx = stack.index(nxt)
                return stack[idx:] + [nxt]
        stack.pop()
        onstack.remove(node)
        return None
    for n in sorted(g.concepts):
        if n not in visited:
            res = dfs(n)
            if res:
                return res
    return None

def has_missing_prereq(g: ConceptGraph, concept: str, prereq: str) -> bool:
    # prereq must be in graph prerequisites for concept
    if concept not in g.concepts or prereq not in g.concepts:
        return True
    # BFS from prereq to see if concept reachable
    q: deque[str] = deque([prereq])
    seen: set[str] = set()
    while q:
        cur = q.popleft()
        if cur == concept:
            return False
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g.adj.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return True
