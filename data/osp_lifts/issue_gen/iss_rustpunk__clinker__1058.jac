"""rustpunk/clinker#1058 — Pipeline composition lineage node enumeration."""

node PipeNode {
    has name: str;
    has in_body: bool = False;
}

edge FlowsTo {}

obj PipelineStore {
    has nodes: dict[str, PipeNode] = {};
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with PipeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:FlowsTo:->] else { disengage; };
    }
}

walker AscendWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with PipeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        parents = [here <-:FlowsTo:<-][?:PipeNode];
        if len(parents) == 0 { disengage; }
        visit [parents[0]];
    }
}

def load_pipeline(
    nodes: list[str],
    edges: list[tuple[str, str]],
    body_nodes: list[str] | None = None,
) -> PipelineStore {
    ps = PipelineStore();
    body_set: dict[str, bool] = {};
    if body_nodes is not None {
        for b in body_nodes { body_set[b] = True; }
    }
    for n in nodes {
        in_b = n in body_set;
        nd = PipeNode(name=n, in_body=in_b);
        root ++> nd;
        ps.nodes[n] = nd;
    }
    for (src, dst) in edges {
        a = ps.nodes.get(src, None);
        b = ps.nodes.get(dst, None);
        if a is not None and b is not None { a +>:FlowsTo:+> b; }
    }
    return ps;
}

def all_lineage_nodes(store: PipelineStore, start: str) -> list[str] {
    nd = store.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn LineageWalk(claimed={}, found=[]);
    aw = nd spawn AscendWalk(claimed={}, chain=[]);
    combined: dict[str, bool] = {};
    for x in w.found { combined[x] = True; }
    for x in aw.chain { combined[x] = True; }
    out: list[str] = [];
    for k in combined.keys() { out.append(k); }
    return sorted(out);
}

def composition_body_nodes(store: PipelineStore) -> list[str] {
    out: list[str] = [];
    for k in store.nodes.keys() {
        if store.nodes[k].in_body { out.append(k); }
    }
    return sorted(out);
}

def missing_binding(store: PipelineStore, pipe_name: str) -> bool {
    nd = store.nodes.get(pipe_name, None);
    if nd is None { return True; }
    if nd.in_body and len([nd <-:FlowsTo:<-]) == 0 { return True; }
    return False;
}
