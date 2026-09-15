# Bloodline (bidirectional) connected-component traversal.
# staudenmeir/laravel-adjacency-list#265

node GraphNode {
    has nid: str;
}

edge Link {}

obj BloodlineGraph {
    has by_id: dict[str, GraphNode] = {};

    def add_node(nid: str) {
        if nid in self.by_id {
            return;
        }
        nd = GraphNode(nid=nid);
        root ++> nd;
        self.by_id[nid] = nd;
    }

    def add_link(a: str, b: str) {
        na = self.by_id[a];
        nb = self.by_id[b];
        na +>:Link:+> nb;
        nb +>:Link:+> na;
    }

    def bloodline(node_id: str) -> list[str] {
        if node_id not in self.by_id {
            return [];
        }
        start = self.by_id[node_id];
        w = start spawn BloodlineWalker(claimed={}, found=[]);
        w.found.sort();
        return w.found;
    }
}

walker BloodlineWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can trace with GraphNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.found.append(here.nid);
        print(here.nid);
        nbrs: list[GraphNode] = [];
        for nb in [here ->:Link:->][?:GraphNode] {
            nbrs.append(nb);
        }
        if len(nbrs) > 0 {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

walker BloodlineBoot {
    has grp: BloodlineGraph;
    has seed: str;

    can setup with entry {
        got = self.grp.bloodline(self.seed);
        print(len(got));
        disengage;
    }
}

with entry {
    g = BloodlineGraph();
    g.add_node("58");
    g.add_node("59");
    g.add_link("58", "59");
    root spawn BloodlineBoot(grp=g, seed="58");
}
