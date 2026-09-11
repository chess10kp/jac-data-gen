"""SaltyPatron/Laplace#924 — N-hop substrate reachability."""

node Entity { has eid: str; }
edge Links {}

obj SubstrateGraph {
    has entities: dict[str, Entity] = {};
}

walker HopWalk {
    has max_hops: int;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth: dict[str, int] = {};

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.reached.append(here.eid);
        cur = self.depth.get(here.eid, 0);
        if cur >= self.max_hops { disengage; }
        for nxt in [here ->:Links:->][?:Entity] {
            if not (nxt.eid in self.depth) {
                self.depth[nxt.eid] = cur + 1;
                visit [nxt];
            }
        }
    }
}

def load_substrate(entities: list[str], links: list[tuple[str, str]]) -> SubstrateGraph {
    g = SubstrateGraph();
    for eid in entities {
        nd = Entity(eid=eid);
        root ++> nd;
        g.entities[eid] = nd;
    }
    for (src, dst) in links {
        s = g.entities.get(src, None);
        d = g.entities.get(dst, None);
        if s is not None and d is not None { s +>:Links:+> d; }
    }
    return g;
}

def n_hop_neighbors(graph: SubstrateGraph, seed: str, hops: int) -> list[str] {
    nd = graph.entities.get(seed, None);
    if nd is None or hops < 0 { return []; }
    w = nd spawn HopWalk(
        max_hops=hops,
        claimed={},
        reached=[],
        depth={seed: 0},
    );
    return sorted(w.reached);
}

def reachable_within(graph: SubstrateGraph, seed: str, hops: int) -> bool {
    return len(n_hop_neighbors(graph, seed, hops)) > 0;
}
