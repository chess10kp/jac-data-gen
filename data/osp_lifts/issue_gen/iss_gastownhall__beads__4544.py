"""Dependency cycle detection inspired by gastownhall/beads#4544."""

from collections import defaultdict


class DepStore:
    """Handle for a dependency graph built from (dependent, dependency) edges."""

    def __init__(self) -> None:
        self.adj: dict[str, list[str]] = defaultdict(list)
        self.nodes: set[str] = set()


def build_dependency_graph(edges: list[tuple[str, str]]) -> DepStore:
    store = DepStore()
    for src, dst in edges:
        store.adj[src].append(dst)
        store.nodes.add(src)
        store.nodes.add(dst)
    return store


def _naive_path_dfs(
    store: DepStore, start: str, on_path: set[str], found: list[bool]
) -> None:
    # Simulates UNION ALL recursive CTE: only path-local membership, no global visited.
    if found[0]:
        return
    if start in on_path:
        found[0] = True
        return
    on_path.add(start)
    for nxt in store.adj.get(start, []):
        _naive_path_dfs(store, nxt, on_path, found)
        if found[0]:
            return
    on_path.remove(start)


def has_cycle_naive(store: DepStore) -> bool:
    for node in sorted(store.nodes):
        found = [False]
        _naive_path_dfs(store, node, set(), found)
        if found[0]:
            return True
    return False


def has_cycle(store: DepStore) -> bool:
    color: dict[str, int] = {n: 0 for n in store.nodes}  # 0=white 1=gray 2=black

    def dfs(u: str) -> bool:
        color[u] = 1
        for v in store.adj.get(u, []):
            if color[v] == 1:
                return True
            if color[v] == 0 and dfs(v):
                return True
        color[u] = 2
        return False

    for n in sorted(store.nodes):
        if color[n] == 0 and dfs(n):
            return True
    return False


def all_nodes(store: DepStore) -> list[str]:
    return sorted(store.nodes)
