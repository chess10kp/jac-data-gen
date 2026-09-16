"""Cycle-safe STEP oriented-edge resolution — prusa3d/PrusaSlicer#11305."""

node OrientedEdge {
    has eid: str;
}

node Vertex {
    has vid: str;
}

edge Starts {}
edge Ends {}

walker OrientedTraceWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_oe with OrientedEdge entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        print("trace_hop", here.eid);
        kids: list[OrientedEdge] = [];
        for ch in [here ->:Starts:->][?:OrientedEdge] {
            kids.append(ch);
        }
        for ch in [here ->:Ends:->][?:OrientedEdge] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
    }

    can step_v with Vertex entry {
        print("trace_vertex", here.vid);
        disengage;
    }
}

def _ensure_oe(store: dict[str, OrientedEdge], eid: str) -> OrientedEdge {
    if eid in store {
        return store[eid];
    }
    nd = OrientedEdge(eid=eid);
    root ++> nd;
    store[eid] = nd;
    return nd;
}

def _ensure_v(store: dict[str, Vertex], vid: str) -> Vertex {
    if vid in store {
        return store[vid];
    }
    vtx = Vertex(vid=vid);
    root ++> vtx;
    store[vid] = vtx;
    return vtx;
}

def _link_ref(
    oe: OrientedEdge,
    ref: str,
    which: str,
    ostore: dict[str, OrientedEdge],
    vstore: dict[str, Vertex]
) -> None {
    toks: list[str] = ref.split(":");
    kind: str = toks[0];
    rid: str = toks[1];
    if kind == "v" {
        vtx = _ensure_v(vstore, rid);
        if which == "start" {
            oe +>:Starts:+> vtx;
        } else {
            oe +>:Ends:+> vtx;
        }
    } else {
        tgt = _ensure_oe(ostore, rid);
        if which == "start" {
            oe +>:Starts:+> tgt;
        } else {
            oe +>:Ends:+> tgt;
        }
    }
}

def _wire_topology(
    specs: list[list[str]]
) -> tuple[dict[str, OrientedEdge], OrientedEdge | None] {
    ostore: dict[str, OrientedEdge] = {};
    vstore: dict[str, Vertex] = {};
    for spec in specs {
        eid: str = spec[0];
        oe = _ensure_oe(ostore, eid);
        _link_ref(oe, spec[1], "start", ostore, vstore);
        _link_ref(oe, spec[2], "end", ostore, vstore);
    }
    return (ostore, None);
}

def _root_oe(ostore: dict[str, OrientedEdge], root_eid: str) -> OrientedEdge | None {
    if root_eid in ostore {
        return ostore[root_eid];
    }
    return None;
}

def safe_trace_edge_chain(specs: list[list[str]], root_eid: str) -> list[str] {
    ostore: dict[str, OrientedEdge] = {};
    vstore: dict[str, Vertex] = {};
    for spec in specs {
        eid: str = spec[0];
        oe = _ensure_oe(ostore, eid);
        _link_ref(oe, spec[1], "start", ostore, vstore);
        _link_ref(oe, spec[2], "end", ostore, vstore);
    }
    root_node: OrientedEdge | None = _root_oe(ostore, root_eid);
    if root_node is None {
        return [];
    }
    w = root_node spawn OrientedTraceWalker(claimed={});
    print("safe_trace_done", root_eid, len(w.found));
    return w.found;
}

def oriented_edge_ids(specs: list[list[str]]) -> list[str] {
    ids: list[str] = [];
    for spec in specs {
        ids.append(spec[0]);
    }
    return sorted(ids);
}

def has_oriented_edge(specs: list[list[str]], eid: str) -> bool {
    for spec in specs {
        if spec[0] == eid {
            return True;
        }
    }
    return False;
}
