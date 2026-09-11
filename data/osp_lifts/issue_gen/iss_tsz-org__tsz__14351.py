"""tsz-org/tsz#14351 — identity resolution, SCC materialize-once, termination."""

from collections import defaultdict, deque


class LineageStore:
    def __init__(self) -> None:
        self.alias_map: dict[str, str] = {}
        self.adj: dict[str, list[str]] = defaultdict(list)
        self.nodes: set[str] = set()
        self.scc_cache: list[list[str]] | None = None


def canonical_id(store: LineageStore, node_id: str) -> str:
    cur = node_id
    seen: set[str] = set()
    while cur in store.alias_map:
        if cur in seen:
            return cur
        seen.add(cur)
        cur = store.alias_map[cur]
    return cur


def build_lineage(
    edges: list[tuple[str, str]],
    aliases: dict[str, str] | None = None,
) -> LineageStore:
    store = LineageStore()
    if aliases:
        store.alias_map.update(aliases)
    for src, dst in edges:
        cs, cd = canonical_id(store, src), canonical_id(store, dst)
        store.adj[cs].append(cd)
        store.nodes.add(cs)
        store.nodes.add(cd)
    return store


def _forward(store: LineageStore, start: str) -> set[str]:
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        u = q.popleft()
        if u in seen:
            continue
        seen.add(u)
        for v in store.adj.get(u, []):
            if v not in seen:
                q.append(v)
    return seen


def _backward(store: LineageStore, start: str) -> set[str]:
    rev: dict[str, list[str]] = defaultdict(list)
    for u, outs in store.adj.items():
        for v in outs:
            rev[v].append(u)
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        u = q.popleft()
        if u in seen:
            continue
        seen.add(u)
        for v in rev.get(u, []):
            if v not in seen:
                q.append(v)
    return seen


def materialize_sccs(store: LineageStore) -> list[list[str]]:
    if store.scc_cache is not None:
        return store.scc_cache
    claimed: set[str] = set()
    sccs: list[list[str]] = []
    for n in sorted(store.nodes):
        if n in claimed:
            continue
        fwd = _forward(store, n)
        bwd = _backward(store, n)
        comp = sorted(fwd & bwd)
        for x in comp:
            claimed.add(x)
        sccs.append(comp)
    store.scc_cache = sorted(sccs, key=lambda c: c[0])
    return store.scc_cache


def has_cycle(store: LineageStore) -> bool:
    for comp in materialize_sccs(store):
        if len(comp) > 1:
            return True
    for u in store.nodes:
        if u in store.adj.get(u, []):
            return True
    color: dict[str, int] = {n: 0 for n in store.nodes}
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


def condensation_topo(store: LineageStore) -> list[str]:
    sccs = materialize_sccs(store)
    rep: dict[str, str] = {}
    for comp in sccs:
        r = comp[0]
        for x in comp:
            rep[x] = r
    indeg: dict[str, int] = {comp[0]: 0 for comp in sccs}
    adj: dict[str, set[str]] = {comp[0]: set() for comp in sccs}
    for u in store.nodes:
        for v in store.adj.get(u, []):
            ru, rv = rep[u], rep[v]
            if ru != rv:
                if rv not in adj[ru]:
                    adj[ru].add(rv)
                    indeg[rv] += 1
    q: deque[str] = deque(sorted([r for r, d in indeg.items() if d == 0]))
    out: list[str] = []
    while q:
        u = q.popleft()
        out.append(u)
        for v in sorted(adj.get(u, set())):
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return out


def terminates(store: LineageStore) -> bool:
    return not has_cycle(store)


def reachable_from(store: LineageStore, start: str) -> list[str]:
    cs = canonical_id(store, start)
    if cs not in store.nodes:
        return []
    return sorted(_forward(store, cs))
