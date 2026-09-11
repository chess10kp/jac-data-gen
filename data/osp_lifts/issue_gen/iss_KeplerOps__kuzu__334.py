"""KeplerOps/kuzu#334 -- recursive vs attribute-hop performance."""

from __future__ import annotations

from collections import deque

class Graph:
    def __init__(self) -> None:
        self.nodes: set[str] = set()
        self.types: dict[str, str] = {}
        self.adj: dict[str, list[str]] = {}  # directed
        self.rev: dict[str, list[str]] = {}

def make_graph() -> Graph:
    return Graph()

def add_node(g: Graph, nid: str, typ: str) -> None:
    if nid in g.nodes:
        raise ValueError("duplicate node")
    g.nodes.add(nid)
    g.types[nid] = typ
    g.adj.setdefault(nid, [])
    g.rev.setdefault(nid, [])

def add_edge(g: Graph, src: str, dst: str) -> None:
    if src not in g.nodes or dst not in g.nodes:
        raise KeyError("unknown node")
    g.adj[src].append(dst)
    g.rev[dst].append(src)

def k_hop_reachable(g: Graph, start: str, k: int) -> set[str]:
    # BFS limited to exactly k hops via queue walk (hand-rolled)
    if start not in g.nodes:
        return set()
    cur: set[str] = {start}
    for _ in range(k):
        nxt: set[str] = set()
        for n in cur:
            for nb in g.adj.get(n, []):
                nxt.add(nb)
        cur = nxt
        if not cur:
            break
    return cur

def count_via_attribute_chain(g: Graph, a_nodes: list[str]) -> int:
    # non-recursive: A -> Attribute -> C chain as in issue
    count = 0
    for a in a_nodes:
        if g.types.get(a) != "A":
            continue
        for attr in g.adj.get(a, []):
            if g.types.get(attr) != "Attribute":
                continue
            for c in g.adj.get(attr, []):
                if g.types.get(c) == "C":
                    count += 1
    return count

def count_via_recursive(g: Graph, a_nodes: list[str]) -> int:
    # recursive [*2..2] equivalent: 2-hop from A to C
    count = 0
    for a in a_nodes:
        reached = k_hop_reachable(g, a, 2)
        for r in reached:
            if g.types.get(r) == "C":
                count += 1
    return count

def shortest_hops(g: Graph, target: str, source_type: str) -> set[str]:
    # BFS from target backward via rev edges up to 6 hops (SHORTEST 1..6)
    if target not in g.nodes:
        return set()
    seen: set[str] = set([target])
    frontier: deque[tuple[str, int]] = deque([(target, 0)])
    reachable: set[str] = set()
    while frontier:
        cur, d = frontier.popleft()
        if d >= 6:
            continue
        for prev in g.rev.get(cur, []):
            if prev not in seen:
                seen.add(prev)
                reachable.add(prev) if g.types.get(prev) == source_type else None
                # actually add if type matches, still traverse
                if g.types.get(prev) == source_type:
                    reachable.add(prev)
                frontier.append((prev, d + 1))
            elif g.types.get(prev) == source_type and d + 1 <= 6:
                reachable.add(prev)
    # filter only source_type
    return {n for n in reachable if g.types.get(n) == source_type}

def has_cycle(g: Graph) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()
    def dfs(n: str) -> bool:
        visited.add(n)
        stack.add(n)
        for nb in g.adj.get(n, []):
            if nb not in visited:
                if dfs(nb):
                    return True
            elif nb in stack:
                return True
        stack.remove(n)
        return False
    for n in list(g.nodes):
        if n not in visited:
            if dfs(n):
                return True
    return False
