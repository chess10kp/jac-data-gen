"""Stewie-pixel/claude-with-leetcode#520 — Remove Methods From Project reachability."""

node Method { has idx: int; }
edge Invokes {}

obj MethodGraph {
    has nodes: dict[int, Method] = {};
}

def _build_graph(n: int, invocations: list[list[int]]) -> MethodGraph {
    g = MethodGraph();
    for i in range(n) {
        nd = Method(idx=i);
        root ++> nd;
        g.nodes[i] = nd;
    }
    for pair in invocations {
        a = pair[0];
        b = pair[1];
        src = g.nodes.get(a, None);
        dst = g.nodes.get(b, None);
        if src is not None and dst is not None { src +>:Invokes:+> dst; }
    }
    return g;
}

def remaining_methods(
    n: int,
    k: int,
    invocations: list[list[int]],
) -> list[int] {
    g = _build_graph(n, invocations);
    start = g.nodes.get(k, None);
    if start is None { return [i for i in range(n)]; }
    claimed: dict[int, bool] = {k: True};
    snap: list[int] = [k];
    i = 0;
    while i < len(snap) {
        u = snap[i];
        i += 1;
        nd = g.nodes.get(u, None);
        if nd is None { continue; }
        for v in [nd ->:Invokes:->][?:Method] {
            if v.idx not in claimed {
                claimed[v.idx] = True;
                snap.append(v.idx);
            }
        }
    }
    for pair in invocations {
        a = pair[0];
        b = pair[1];
        if not (a in claimed) and (b in claimed) {
            out: list[int] = [];
            for j in range(n) { out.append(j); }
            return out;
        }
    }
    out: list[int] = [];
    for j in range(n) {
        if not (j in claimed) { out.append(j); }
    }
    return out;
}
