"""CSR adjacency index for native graph traversal. lance-format/lance-graph#159."""

from __future__ import annotations

from collections import defaultdict, deque


class CsrGraph:
    """Compressed sparse row adjacency: row_ptr + col_idx over stable node ids."""

    def __init__(self, node_ids: list[str], row_ptr: list[int], col_idx: list[int]) -> None:
        self.node_ids = list(node_ids)
        self.row_ptr = list(row_ptr)
        self.col_idx = list(col_idx)
        self._id_to_ix = {n: i for i, n in enumerate(self.node_ids)}


def build_csr(edges: list[tuple[str, str]]) -> CsrGraph:
    adj: dict[str, list[str]] = defaultdict(list)
    nodes: set[str] = set()
    for src, dst in edges:
        adj[src].append(dst)
        nodes.add(src)
        nodes.add(dst)
    node_ids = sorted(nodes)
    row_ptr = [0]
    col_idx: list[str] = []
    for n in node_ids:
        nbrs = sorted(adj.get(n, []))
        col_idx.extend(nbrs)
        row_ptr.append(len(col_idx))
    return CsrGraph(node_ids, row_ptr, col_idx)


def neighbors_csr(graph: CsrGraph, node: str) -> list[str]:
    if node not in graph._id_to_ix:
        return []
    i = graph._id_to_ix[node]
    lo, hi = graph.row_ptr[i], graph.row_ptr[i + 1]
    return list(graph.col_idx[lo:hi])


def reachable_bfs(graph: CsrGraph, start: str) -> list[str]:
    if start not in graph._id_to_ix:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nb in neighbors_csr(graph, cur):
            if nb not in seen:
                q.append(nb)
    return sorted(seen)


def reachable_dfs(graph: CsrGraph, start: str) -> list[str]:
    if start not in graph._id_to_ix:
        return []
    seen: set[str] = set()
    stack: list[str] = [start]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nb in reversed(neighbors_csr(graph, cur)):
            if nb not in seen:
                stack.append(nb)
    return sorted(seen)
