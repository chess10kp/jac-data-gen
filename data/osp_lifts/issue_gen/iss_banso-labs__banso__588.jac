"""banso-labs/banso#588 — Reachability index for blast-radius forward impact."""

obj CallGraph {
    has nodes: dict[str, CallNode] = {};
}

node CallNode {
    has nid: str;
}

edge Calls {}

walker ForwardWalk {
    has claimed: dict[str, bool] = {};
    has node_depth: dict[str, int] = {};
    has reached: list[str] = [];
    has max_depth: int = 64;

    can step with CallNode entry {
        if here.nid in self.claimed { skip; }
        if here.nid not in self.node_depth { self.node_depth[here.nid] = 0; }
        cur_depth = self.node_depth[here.nid];
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        if cur_depth >= self.max_depth { disengage; }
        for nxt in [here ->:Calls:->][?:CallNode] {
            if nxt.nid not in self.node_depth {
                self.node_depth[nxt.nid] = cur_depth + 1;
            }
        }
        visit [->:Calls:->] else { disengage; };
    }
}

walker CallerWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with CallNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.chain.append(here.nid);
        callers = [here <-:Calls:<-][?:CallNode];
        if not callers { disengage; }
        pick = callers[0];
        for c in callers {
            if c.nid < pick.nid { pick = c; }
        }
        visit [pick];
    }
}

def load_call_graph(
    nodes: list[str],
    calls: list[tuple[str, str]],
) -> CallGraph {
    g = CallGraph();
    for n in nodes {
        if n not in g.nodes {
            nd = CallNode(nid=n);
            root ++> nd;
            g.nodes[n] = nd;
        }
    }
    for (src, dst) in calls {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:Calls:+> b; }
    }
    return g;
}

def forward_reachable(g: CallGraph, seed: str, max_depth: int) -> list[str] {
    anchor = g.nodes.get(seed, None);
    if anchor is None { return []; }
    w = anchor spawn ForwardWalk(claimed={}, node_depth={}, reached=[], max_depth=max_depth);
    return sorted(w.reached);
}

def is_reachable(g: CallGraph, src: str, dst: str) -> bool {
    hits = forward_reachable(g, src, 64);
    return dst in hits;
}

def caller_chain(g: CallGraph, node_id: str) -> list[str] {
    anchor = g.nodes.get(node_id, None);
    if anchor is None { return []; }
    w = anchor spawn CallerWalk(claimed={}, chain=[]);
    return w.chain;
}
