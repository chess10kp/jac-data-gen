"""yesiamrajeev/Hacktoberfest2025#332 — graph traversal BFS/DFS lift."""

node GVert {
    has vid: str;
    has ord: int = 0;
}

edge GEdge {}

obj GraphHandle {
    has directed: bool = False;
    has verts: dict[str, GVert] = {};
    has next_ord: int = 0;
}

def make_graph(directed: bool = False) -> GraphHandle {
    return GraphHandle(directed=directed);
}

def _ensure_vert(g: GraphHandle, vid: str) -> GVert {
    if vid in g.verts {
        return g.verts[vid];
    }
    v = GVert(vid=vid, ord=g.next_ord);
    g.next_ord += 1;
    g.verts[vid] = v;
    root ++> v;
    return v;
}

def add_edge(g: GraphHandle, u: str, v: str) {
    a = _ensure_vert(g, u);
    b = _ensure_vert(g, v);
    a +>:GEdge:+> b;
    if not g.directed {
        b +>:GEdge:+> a;
    }
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GVert entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print(here.vid);
        nbrs: list[GVert] = [here ->:GEdge:->][?:GVert];
        nxt: list[str] = [];
        for ch in nbrs {
            if ch.vid not in self.claimed {
                nxt.append(ch.vid);
            }
        }
        nxt = sorted(nxt);
        queued: bool = False;
        for kv in nxt {
            for ch in nbrs {
                if ch.vid == kv {
                    visit [ch];
                    queued = True;
                    break;
                }
            }
        }
        if not queued { disengage; }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GVert entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print(here.vid);
        nbrs: list[GVert] = [here ->:GEdge:->][?:GVert];
        nxt: list[str] = [];
        for ch in nbrs {
            if ch.vid not in self.claimed {
                nxt.append(ch.vid);
            }
        }
        nxt = sorted(nxt);
        idx: int = len(nxt) - 1;
        pushed: bool = False;
        while idx >= 0 {
            kv = nxt[idx];
            for ch in nbrs {
                if ch.vid == kv {
                    visit :0: [ch];
                    pushed = True;
                    break;
                }
            }
            idx -= 1;
        }
        if not pushed { disengage; }
    }
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has parent_vid: str = "";
    has found: bool = False;

    can probe with GVert entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        print(here.vid);
        saved_parent: str = self.parent_vid;
        nbrs: list[GVert] = [here ->:GEdge:->][?:GVert];
        nxt: list[str] = [];
        for ch in nbrs {
            if ch.vid in self.claimed and ch.vid != saved_parent {
                self.found = True;
            }
            if ch.vid not in self.claimed {
                nxt.append(ch.vid);
            }
        }
        nxt = sorted(nxt);
        idx: int = len(nxt) - 1;
        pushed: bool = False;
        while idx >= 0 {
            self.parent_vid = here.vid;
            kv = nxt[idx];
            for ch in nbrs {
                if ch.vid == kv {
                    visit :0: [ch];
                    pushed = True;
                    break;
                }
            }
            idx -= 1;
        }
        if not pushed { disengage; }
    }
}

def bfs_order(g: GraphHandle, start: str) -> list[str] {
    if start not in g.verts { return []; }
    w = g.verts[start] spawn BfsWalker(claimed={});
    return w.order;
}

def dfs_order(g: GraphHandle, start: str) -> list[str] {
    if start not in g.verts { return []; }
    w = g.verts[start] spawn DfsWalker(claimed={});
    return w.order;
}

def connected_components(g: GraphHandle) -> list[list[str]] {
    comps: list[list[str]] = [];
    global_claimed: dict[str, bool] = {};
    keys: list[str] = sorted(g.verts.keys());
    for vid in keys {
        if vid in global_claimed { continue; }
        w = g.verts[vid] spawn DfsWalker(claimed=global_claimed);
        row: list[str] = [];
        for x in w.order { row.append(x); }
        comps.append(row);
    }
    return comps;
}

def has_undirected_cycle(g: GraphHandle) -> bool {
    if g.directed { return False; }
    global_claimed: dict[str, bool] = {};
    keys: list[str] = sorted(g.verts.keys());
    for vid in keys {
        if vid in global_claimed { continue; }
        w = g.verts[vid] spawn CycleWalker(claimed=global_claimed, parent_vid="", found=False);
        if w.found { return True; }
    }
    return False;
}

walker DemoWalker {
    can boot with Root entry {
        g = make_graph(directed=False);
        add_edge(g, "1", "2");
        add_edge(g, "1", "3");
        add_edge(g, "2", "4");
        sv = g.verts["1"];
        w = sv spawn BfsWalker(claimed={});
        print(w.order);
        disengage;
    }
}

with entry {
    root spawn DemoWalker;
}
