"""agent-pipe-shared/agent-pipeline#78 — documentation estate reference graph."""

obj DocEstate {
    has stamp: int = 1;
    has paths: list[str] = [];
    has nodes: dict[str, DocPath] = {};
    has adj: dict[str, list[str]] = {};
}

node DocPath {
    has path: str;
    has kind: str = "";
}

edge References {}

walker ReachFold {
    has claimed: dict[str, bool] = {};
    has seen: list[str] = [];

    can walk with DocPath entry {
        pid = here.path;
        if pid in self.claimed { skip; }
        self.claimed[pid] = True;
        self.seen.append(pid);
        visit [here->:References:->][?:DocPath];
    }
}

def _dfs_cycle(
    adj: dict[str, list[str]],
    color: dict[str, int],
    found: list[str],
    `node: str,
) {
    color[`node] = 1;
    for nxt in adj.get(`node, []) {
        st = color.get(nxt, 0);
        if st == 1 {
            dup = False;
            for x in found {
                if x == nxt { dup = True; }
            }
            if not dup { found.append(nxt); }
        } elif st == 0 {
            _dfs_cycle(adj, color, found, nxt);
        }
    }
    color[`node] = 2;
}

def load_estate(
    docs: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> DocEstate {
    estate = DocEstate(stamp=1, paths=[], nodes={}, adj={});
    for (path, kind) in docs {
        if not (path in estate.nodes) {
            nd = DocPath(path=path, kind=kind);
            root ++> nd;
            estate.nodes[path] = nd;
            estate.paths.append(path);
            estate.adj[path] = [];
        }
    }
    for (src, dst) in refs {
        s = estate.nodes.get(src, None);
        d = estate.nodes.get(dst, None);
        if s is not None and d is not None {
            s +>:References:+> d;
            estate.adj[src].append(dst);
        }
    }
    return estate;
}

def reachable_docs(estate: DocEstate, start: str) -> list[str] {
    nd = estate.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachFold(claimed={}, seen=[]);
    return sorted(w.seen);
}

def reference_cycle_nodes(estate: DocEstate) -> list[str] {
    color: dict[str, int] = {};
    found: list[str] = [];
    for n in sorted(estate.paths) {
        if color.get(n, 0) == 0 {
            _dfs_cycle(estate.adj, color, found, n);
        }
    }
    return sorted(found);
}

def orphan_docs(estate: DocEstate, roots: list[str]) -> list[str] {
    reachable: dict[str, bool] = {};
    for r in roots {
        for p in reachable_docs(estate, r) { reachable[p] = True; }
    }
    out: list[str] = [];
    for p in estate.paths {
        if not (p in reachable) { out.append(p); }
    }
    return sorted(out);
}

def journey_layers(estate: DocEstate) -> list[list[str]] {
    indegree: dict[str, int] = {};
    for p in estate.paths { indegree[p] = 0; }
    for src in estate.paths {
        for dst in estate.adj.get(src, []) {
            indegree[dst] += 1;
        }
    }
    layers: list[list[str]] = [];
    visited: dict[str, bool] = {};
    ready: dict[str, bool] = {};
    for pid in indegree.keys() {
        if indegree[pid] == 0 { ready[pid] = True; }
    }
    while len(ready) > 0 {
        layer = sorted([p for p in ready.keys()]);
        layers.append(layer);
        next_ready: dict[str, bool] = {};
        for node in layer {
            visited[node] = True;
            for nxt in estate.adj.get(node, []) {
                if not (nxt in visited) {
                    indegree[nxt] -= 1;
                    if indegree[nxt] == 0 { next_ready[nxt] = True; }
                }
            }
        }
        ready = next_ready;
    }
    return layers;
}
