"""Concorda-Sailing/knowledge-graph#56 — dossier outbound dependency reach."""

node Dossier {
    has name: str;
}

edge Outbound {}

obj DossierGraph {
    has nodes: dict[str, Dossier] = {};
}

walker OutboundWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Dossier entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Outbound:->][?:Dossier];
    }
}

def load_dossiers(nodes: list[str], edges: list[tuple[str, str]]) -> DossierGraph {
    g = DossierGraph();
    for n in nodes {
        nd = Dossier(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (src, dst) in edges {
        s = g.nodes.get(src, None);
        d = g.nodes.get(dst, None);
        if s is not None and d is not None { s +>:Outbound:+> d; }
    }
    return g;
}

def outbound_reach(store: DossierGraph, `node: str) -> list[str] {
    nd = store.nodes.get(`node, None);
    if nd is None { return []; }
    w = nd spawn OutboundWalk(claimed={}, reached=[]);
    out: list[str] = [];
    for n in w.reached {
        if n != `node { out.append(n); }
    }
    return sorted(out);
}
