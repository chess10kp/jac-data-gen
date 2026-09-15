"""OpenGenus/cosmos#4641 — Kahn's algorithm for topological sorting."""

node Vtx {
    has vid: str;
    has indeg: int = 0;
}

edge Arc {}

walker LogNodes {
    has claimed: dict[str, bool] = {};

    can log with Vtx entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        print(here.vid);
        disengage;
    }
}

def topological_sort(vertices: list[str], edges: list[list[str]]) -> list[str] {
    lookup: dict[str, Vtx] = {};
    for vid in vertices {
        nd = Vtx(vid=vid);
        root ++> nd;
        lookup[vid] = nd;
    }
    for pair in edges {
        if len(pair) < 2 { continue; }
        u_id = pair[0];
        v_id = pair[1];
        if u_id not in lookup { continue; }
        if v_id not in lookup { continue; }
        u = lookup[u_id] as Vtx;
        v = lookup[v_id] as Vtx;
        u +>:Arc:+> v;
        v.indeg += 1;
    }
    stamp_claimed: dict[str, bool] = {};
    for vid in vertices {
        nd = lookup[vid] as Vtx;
        wk = nd spawn LogNodes(claimed=stamp_claimed);
    }
    rem: dict[str, int] = {};
    for vid in vertices {
        nd = lookup[vid] as Vtx;
        rem[vid] = nd.indeg;
    }
    queue: list[str] = [];
    for vid in vertices {
        if rem[vid] == 0 {
            queue.append(vid);
        }
    }
    order: list[str] = [];
    qi: int = 0;
    while qi < len(queue) {
        cur = queue[qi];
        qi += 1;
        order.append(cur);
        u = lookup[cur] as Vtx;
        succs: list[Vtx] = [u ->:Arc:->][?:Vtx];
        for succ in succs {
            sid = succ.vid;
            rem[sid] -= 1;
            if rem[sid] == 0 {
                queue.append(sid);
            }
        }
    }
    if len(order) != len(vertices) {
        return [];
    }
    return order;
}
