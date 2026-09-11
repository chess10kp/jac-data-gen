"""PostGraphDB/postgraph#1081 — adjacency-list pages split from property pages."""

import from math { sqrt }

node Vertex {
    has vid: str;
    has props: dict = {};
    has vector: tuple[float, ...] = ();
}

edge AdjOut: Vertex --> Vertex {
    has eid: str;
    has props: dict = {};
}

obj GraphStorage {
    has vertex_props: dict[str, dict] = {};
    has edge_props: dict[str, dict] = {};
    has vectors: dict[str, tuple[float, ...]] = {};
    has vertices: dict[str, Vertex] = {};
}

walker BfsReachWalk {
    has claimed: dict[str, bool] = {};
    has node_depth: dict[str, int] = {};
    has hits: list[str] = [];
    has max_hops: int = 0;
    has origin: str = "";

    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        if not (here.vid in self.node_depth) {
            self.node_depth[here.vid] = 0;
        }
        cur_depth = self.node_depth[here.vid];
        self.claimed[here.vid] = True;
        if here.vid != self.origin {
            self.hits.append(here.vid);
        }
        if cur_depth >= self.max_hops { skip; }
        nbrs = [here ->:AdjOut:->][?:Vertex];
        names: list[str] = [];
        for n in nbrs { names.append(n.vid); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.vid == nm {
                    if not (n.vid in self.node_depth) {
                        self.node_depth[n.vid] = cur_depth + 1;
                    }
                    visit :0: [n];
                }
            }
        }
    }
}

walker BfsEdgeWalk {
    has claimed: dict[str, bool] = {};
    has node_depth: dict[str, int] = {};
    has edge_ids: list[str] = [];
    has max_hops: int = 0;

    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        if not (here.vid in self.node_depth) {
            self.node_depth[here.vid] = 0;
        }
        cur_depth = self.node_depth[here.vid];
        self.claimed[here.vid] = True;
        if cur_depth >= self.max_hops { skip; }
        nbrs = [here ->:AdjOut:->][?:Vertex];
        names: list[str] = [];
        for n in nbrs { names.append(n.vid); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.vid == nm {
                    for e in [edge here ->:AdjOut:-> n] {
                        self.edge_ids.append(e.eid);
                    }
                    if not (n.vid in self.claimed) {
                        if not (n.vid in self.node_depth) {
                            self.node_depth[n.vid] = cur_depth + 1;
                        }
                        visit :0: [n];
                    }
                }
            }
        }
    }
}

def make_storage() -> GraphStorage {
    return GraphStorage();
}

def add_vertex(
    storage: GraphStorage,
    vid: str,
    props: dict,
    vector: tuple[float, ...],
) -> None {
    storage.vertex_props[vid] = dict(props);
    storage.vectors[vid] = tuple(vector);
    if vid in storage.vertices {
        nd = storage.vertices[vid];
        nd.props = dict(props);
        nd.vector = tuple(vector);
    } else {
        nd = Vertex(vid=vid, props=dict(props), vector=tuple(vector));
        root ++> nd;
        storage.vertices[vid] = nd;
    }
}

def add_edge(
    storage: GraphStorage,
    eid: str,
    src: str,
    dst: str,
    props: dict,
) -> None {
    if not (src in storage.vertices) or not (dst in storage.vertices) {
        raise KeyError("unknown vertex");
    }
    storage.edge_props[eid] = dict(props);
    a = storage.vertices[src];
    b = storage.vertices[dst];
    a +>:AdjOut(eid=eid, props=dict(props)):+> b;
}

def adjacency_neighbors(storage: GraphStorage, vid: str) -> list[str] {
    v = storage.vertices.get(vid, None);
    if v is None { return []; }
    out: list[str] = [];
    seen: dict[str, bool] = {};
    for n in [v ->:AdjOut:->][?:Vertex] {
        if not (n.vid in seen) {
            seen[n.vid] = True;
            out.append(n.vid);
        }
    }
    return sorted(out);
}

def heap_scan_neighbors(storage: GraphStorage, vid: str) -> list[str] {
    found: dict[str, bool] = {};
    for v in storage.vertices.values() {
        if v.vid != vid { continue; }
        for n in [v ->:AdjOut:->][?:Vertex] {
            found[n.vid] = True;
        }
    }
    out: list[str] = [];
    for k in found { out.append(k); }
    return sorted(out);
}

def bfs_reachable(storage: GraphStorage, start: str, max_hops: int) -> list[str] {
    if start not in storage.vertices { return []; }
    nd = storage.vertices[start];
    w = nd spawn BfsReachWalk(
        claimed={}, node_depth={}, hits=[], max_hops=max_hops, origin=start
    );
    return sorted(w.hits);
}

def bfs_edge_property_refs(
    storage: GraphStorage, start: str, max_hops: int
) -> list[str] {
    if start not in storage.vertices { return []; }
    nd = storage.vertices[start];
    w = nd spawn BfsEdgeWalk(claimed={}, node_depth={}, edge_ids=[], max_hops=max_hops);
    return sorted(w.edge_ids);
}

def neighbors_matching_edge_prop(
    storage: GraphStorage, vid: str, key: str, value: object
) -> list[str] {
    v = storage.vertices.get(vid, None);
    if v is None { return []; }
    out: list[str] = [];
    seen: dict[str, bool] = {};
    for n in [v ->:AdjOut:->][?:Vertex] {
        for e in [edge v ->:AdjOut:-> n] {
            props = storage.edge_props.get(e.eid, {});
            if props.get(key, None) == value {
                if not (n.vid in seen) {
                    seen[n.vid] = True;
                    out.append(n.vid);
                }
                break;
            }
        }
    }
    return sorted(out);
}

def vector_knn(
    storage: GraphStorage, query: tuple[float, ...], k: int
) -> list[str] {
    ranked: list[tuple[float, str]] = [];
    for vid in storage.vectors {
        vec = storage.vectors[vid];
        dist = sqrt(sum((query[i] - vec[i]) ** 2 for i in range(len(query))));
        ranked.append((dist, vid));
    }
    ranked.sort();
    out: list[str] = [];
    for (d, vid) in ranked[:k] { out.append(vid); }
    return out;
}

def storage_views_agree(storage: GraphStorage, vid: str) -> bool {
    return adjacency_neighbors(storage, vid) == heap_scan_neighbors(storage, vid);
}
