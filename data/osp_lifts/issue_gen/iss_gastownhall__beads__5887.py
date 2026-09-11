"""Tree renderer cycle blow-up inspired by gastownhall/beads#5887."""

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


def _naive_render(store: DepStore, start: str, on_path: set[str], out: list[str]) -> None:
    # No global visited set — mirrors bd list tree renderer path (#5887 / #2719).
    if start in on_path:
        return
    on_path.add(start)
    out.append(start)
    for nxt in store.adj.get(start, []):
        _naive_render(store, nxt, on_path, out)
    on_path.remove(start)


def render_tree_naive(store: DepStore, root_id: str) -> list[str]:
    if root_id not in store.nodes:
        raise KeyError(root_id)
    out: list[str] = []
    _naive_render(store, root_id, set(), out)
    return out


def _dfs_cycle(store: DepStore, u: str, color: dict[str, int]) -> bool:
    color[u] = 1
    for v in store.adj.get(u, []):
        if color[v] == 1:
            return True
        if color[v] == 0 and _dfs_cycle(store, v, color):
            return True
    color[u] = 2
    return False


def has_cycle(store: DepStore) -> bool:
    color: dict[str, int] = {n: 0 for n in store.nodes}
    for n in sorted(store.nodes):
        if color[n] == 0 and _dfs_cycle(store, n, color):
            return True
    return False


def render_tree(store: DepStore, root_id: str) -> list[str]:
    if has_cycle(store):
        raise ValueError("cycle detected")
    if root_id not in store.nodes:
        raise KeyError(root_id)
    out: list[str] = []
    claimed: set[str] = set()

    def walk(u: str) -> None:
        if u in claimed:
            return
        claimed.add(u)
        out.append(u)
        for v in store.adj.get(u, []):
            walk(v)

    walk(root_id)
    return out


def all_nodes(store: DepStore) -> list[str]:
    return sorted(store.nodes)
