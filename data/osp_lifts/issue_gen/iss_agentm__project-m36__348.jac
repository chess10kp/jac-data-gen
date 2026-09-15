"""agentm/project-m36#348 — recursive relationship depth traversal."""

node Vertex {
    has vid: int;
    has cid: str;
}

edge Out {}

def _build_graph(edges: list[tuple[int, int]]) -> tuple[Vertex, dict[int, Vertex]] {
    graph_root = Vertex(vid=-1, cid="graph_root");
    root ++> graph_root;
    verts: dict[int, Vertex] = {};
    for pair in edges {
        s = pair[0];
        t = pair[1];
        if s not in verts {
            nv = Vertex(vid=s, cid="v" + str(s));
            verts[s] = nv;
            graph_root ++> nv;
        }
        if t not in verts {
            nv = Vertex(vid=t, cid="v" + str(t));
            verts[t] = nv;
            graph_root ++> nv;
        }
        sv = verts[s];
        tv = verts[t];
        sv +>:Out:+> tv;
    }
    return (graph_root, verts);
}

def _sort_grouped(grouped: dict[int, list[int]]) -> dict[int, list[int]] {
    out: dict[int, list[int]] = {};
    keys: list[int] = [];
    for k in grouped {
        keys.append(k);
    }
    keys = sorted(keys);
    for k in keys {
        vals: list[int] = [];
        for v in grouped[k] {
            vals.append(v);
        }
        out[k] = sorted(vals);
    }
    return out;
}

def _sort_paths(rows: list[list[int]]) -> list[list[int]] {
    copied: list[list[int]] = [];
    for r in rows {
        row: list[int] = [];
        for x in r {
            row.append(x);
        }
        copied.append(row);
    }
    return sorted(copied);
}

walker BfsDepthWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 0;
    has by_depth: dict[int, list[int]] = {};
    has hop: int = 0;
    has origin_vid: int = 0;

    can step with Vertex entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.vid != self.origin_vid and self.hop > 0 and self.hop <= self.max_depth {
            if self.hop not in self.by_depth {
                self.by_depth[self.hop] = [];
            }
            dup = False;
            for x in self.by_depth[self.hop] {
                if x == here.vid {
                    dup = True;
                }
            }
            if not dup {
                self.by_depth[self.hop].append(here.vid);
            }
        }
        print("bfs", here.vid, self.hop);
        if self.hop >= self.max_depth {
            disengage;
        }
        kids: list[Vertex] = [here ->:Out:->][?:Vertex];
        next_hop = self.hop + 1;
        for ch in kids {
            wk = ch spawn BfsDepthWalker(
                claimed=self.claimed,
                max_depth=self.max_depth,
                by_depth=self.by_depth,
                hop=next_hop,
                origin_vid=self.origin_vid
            );
        }
        disengage;
    }
}

walker PathDepthWalker {
    has path_ids: list[int] = [];
    has depth_limit: int = 0;
    has results: list[list[int]] = [];

    can step with Vertex entry {
        cur: list[int] = [];
        for p in self.path_ids {
            cur.append(p);
        }
        cur.append(here.vid);
        edge_count = len(cur) - 1;
        if edge_count == self.depth_limit {
            row: list[int] = [];
            for p in cur {
                row.append(p);
            }
            self.results.append(row);
            print("path_done", here.vid, edge_count);
            disengage;
        }
        if edge_count >= self.depth_limit {
            disengage;
        }
        kids: list[Vertex] = [here ->:Out:->][?:Vertex];
        for ch in kids {
            on_path = False;
            for p in cur {
                if p == ch.vid {
                    on_path = True;
                }
            }
            if not on_path {
                wk = ch spawn PathDepthWalker(
                    path_ids=cur,
                    depth_limit=self.depth_limit,
                    results=self.results
                );
                print("path_extend", ch.vid);
            }
        }
        disengage;
    }
}

def reachable_by_depth(
    edges: list[tuple[int, int]],
    src: int,
    max_depth: int
) -> dict[int, list[int]] {
    (_gr, verts) = _build_graph(edges);
    if src not in verts {
        empty: dict[int, list[int]] = {};
        return empty;
    }
    if max_depth < 1 {
        empty2: dict[int, list[int]] = {};
        return empty2;
    }
    start = verts[src];
    claimed: dict[str, bool] = {};
    by_depth: dict[int, list[int]] = {};
    wk = start spawn BfsDepthWalker(
        claimed=claimed,
        max_depth=max_depth,
        by_depth=by_depth,
        hop=0,
        origin_vid=src
    );
    return _sort_grouped(by_depth);
}

def depth_n_paths(
    edges: list[tuple[int, int]],
    src: int,
    n: int
) -> list[list[int]] {
    (_gr, verts) = _build_graph(edges);
    if src not in verts {
        empty: list[list[int]] = [];
        return empty;
    }
    if n < 1 {
        empty2: list[list[int]] = [];
        return empty2;
    }
    start = verts[src];
    results: list[list[int]] = [];
    wk = start spawn PathDepthWalker(path_ids=[], depth_limit=n, results=results);
    return _sort_paths(results);
}
