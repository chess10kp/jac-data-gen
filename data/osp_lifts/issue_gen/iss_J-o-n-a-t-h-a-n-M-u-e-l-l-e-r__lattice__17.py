"""J-o-n-a-t-h-a-n-M-u-e-l-l-e-r/lattice#17 — Tarjan strongly-connected components."""

from __future__ import annotations


class GraphStore:
    # Hand-rolled adjacency + iterative Tarjan indices/stack.
    def __init__(self) -> None:
        self._adj: dict[str, list[str]] = {}
        self._nodes: set[str] = set()


def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> GraphStore:
    g = GraphStore()
    for n in nodes:
        g._nodes.add(n)
        g._adj.setdefault(n, [])
    for u, v in edges:
        if u in g._nodes and v in g._nodes:
            g._adj.setdefault(u, []).append(v)
            g._adj.setdefault(v, g._adj.get(v, []))
    return g


def strongly_connected_components(store: GraphStore) -> list[list[str]]:
    index = 0
    stack: list[str] = []
    on_stack: set[str] = set()
    indices: dict[str, int] = {}
    lowlink: dict[str, int] = {}
    result: list[list[str]] = []

    for start in sorted(store._nodes):
        if start in indices:
            continue
        work: list[tuple[str, int]] = [(start, 0)]
        while work:
            node, i = work[-1]
            if node not in indices:
                indices[node] = index
                lowlink[node] = index
                index += 1
                stack.append(node)
                on_stack.add(node)
                i = 0
            nbrs = store._adj.get(node, [])
            pushed = False
            while i < len(nbrs):
                w = nbrs[i]
                i += 1
                if w not in indices:
                    work[-1] = (node, i)
                    work.append((w, 0))
                    pushed = True
                    break
                if w in on_stack:
                    lowlink[node] = min(lowlink[node], indices[w])
            if pushed:
                continue
            work.pop()
            if work:
                parent, _ = work[-1]
                lowlink[parent] = min(lowlink[parent], lowlink[node])
            if lowlink[node] == indices[node]:
                comp: list[str] = []
                while True:
                    w = stack.pop()
                    on_stack.discard(w)
                    comp.append(w)
                    if w == node:
                        break
                result.append(sorted(comp))
    return sorted(result, key=lambda c: (len(c), c))


def shortest_cycle_path(store: GraphStore, component: list[str]) -> list[str]:
    if len(component) < 2:
        return list(component)
    comp_set = set(component)
    start = sorted(component)[0]
    parent: dict[str, str | None] = {start: None}
    queue: list[str] = [start]
    target: str | None = None
    while queue and target is None:
        cur = queue.pop(0)
        for nbr in store._adj.get(cur, []):
            if nbr not in comp_set:
                continue
            if nbr not in parent:
                parent[nbr] = cur
                queue.append(nbr)
            elif nbr != parent.get(cur) and (cur != start or nbr != start):
                target = nbr
                closing = cur
                path = [nbr]
                step = closing
                while step is not None and step != nbr:
                    path.append(step)
                    step = parent.get(step)
                path.append(nbr)
                return list(reversed(path))
    return [start]
