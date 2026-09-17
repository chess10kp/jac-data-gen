"""openai/codex#35463 — subagent fork trees replay ancestor token bookkeeping."""

node sess {
    has sid: str;
    has depth: int = 0;
    has genuine: int = 0;
    has logged: int = 0;
}

edge fork {}

obj SessionGraph {
    has graph_root: sess | None = None;
    has nodes: dict[str, sess] = {};
}

walker depth_walk {
    has claimed: dict[str, bool] = {};
    has mx: int = 0;
    can step with sess entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.depth > self.mx { self.mx = here.depth; }
        kids: list[sess] = [];
        for ch in [here ->:fork:->][?:sess] { kids.append(ch); }
        if kids { visit kids; } else { disengage; }
        print(["depth", here.sid, self.mx]);
    }
}

walker quota_walk {
    has claimed: dict[str, bool] = {};
    has naive: int = 0;
    has real: int = 0;
    can step with sess entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.naive = self.naive + here.logged;
        self.real = self.real + here.genuine;
        kids: list[sess] = [];
        for ch in [here ->:fork:->][?:sess] { kids.append(ch); }
        if kids { visit :0: kids; } else { disengage; }
        print(["quota", here.sid, self.naive, self.real]);
    }
}

def make_graph(spec: list[tuple[str, str, int]]) -> SessionGraph {
    g = SessionGraph();
    for row in spec {
        ps = row[0];
        cs = row[1];
        gen = row[2];
        if ps not in g.nodes {
            pn = sess(sid=ps, depth=0, genuine=0, logged=0);
            g.nodes[ps] = pn;
            g.graph_root = pn;
            root ++> pn;
        }
        if cs not in g.nodes {
            pd = g.nodes[ps].depth;
            cn = sess(sid=cs, depth=pd + 1, genuine=gen, logged=gen);
            g.nodes[cs] = cn;
            root ++> cn;
        }
        g.nodes[ps] +>:fork:+> g.nodes[cs];
        apply_fork_replay(g, ps, cs);
    }
    return g;
}

def apply_fork_replay(graph: SessionGraph, parent_sid: str, child_sid: str) -> int {
    if parent_sid not in graph.nodes { return 0; }
    if child_sid not in graph.nodes { return 0; }
    parent = graph.nodes[parent_sid];
    child = graph.nodes[child_sid];
    replayed = parent.logged;
    child.logged = child.genuine + replayed;
    return replayed;
}

def logged_events(graph: SessionGraph, sid: str) -> int {
    if sid not in graph.nodes { return 0; }
    return graph.nodes[sid].logged;
}

def genuine_events(graph: SessionGraph, sid: str) -> int {
    if sid not in graph.nodes { return 0; }
    return graph.nodes[sid].genuine;
}

def subtree_naive_quota(graph: SessionGraph, root_sid: str) -> int {
    if root_sid not in graph.nodes { return 0; }
    start = graph.nodes[root_sid];
    w = start spawn quota_walk(claimed={});
    print(["subtree_naive", w.naive]);
    return w.naive;
}

def subtree_real_quota(graph: SessionGraph, root_sid: str) -> int {
    if root_sid not in graph.nodes { return 0; }
    start = graph.nodes[root_sid];
    w = start spawn quota_walk(claimed={});
    print(["subtree_real", w.real]);
    return w.real;
}

def max_fork_depth(graph: SessionGraph, root_sid: str) -> int {
    if root_sid not in graph.nodes { return 0; }
    start = graph.nodes[root_sid];
    w = start spawn depth_walk(claimed={});
    print(["max_fork_depth", w.mx]);
    return w.mx;
}
