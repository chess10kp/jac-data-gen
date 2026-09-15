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

test "unknown_id_empty" {
    g = BloodlineGraph();
    got = g.bloodline("missing");
    assert len(got) == 0;;
}

test "diamond_adversarial_revisit" {
    g = BloodlineGraph();
    g.add_node("a");
    g.add_node("b");
    g.add_node("c");
    g.add_node("d");
    # edge order forces early revisit before deeper first-visits
    g.add_link("c", "d");
    g.add_link("a", "c");
    g.add_link("b", "d");
    g.add_link("a", "b");
    got = g.bloodline("a");
    exp: list[str] = ["a", "b", "c", "d"];
    assert got == exp;;
}

test "cycle_triangle_distinct" {
    g = BloodlineGraph();
    g.add_node("1");
    g.add_node("2");
    g.add_node("3");
    g.add_link("1", "2");
    g.add_link("2", "3");
    g.add_link("3", "1");
    got = g.bloodline("2");
    exp: list[str] = ["1", "2", "3"];
    assert got == exp;;
}

test "isolated_single_node" {
    g = BloodlineGraph();
    g.add_node("solo");
    got = g.bloodline("solo");
    assert got == ["solo"];;
}

test "bidirectional_from_either_endpoint" {
    g = BloodlineGraph();
    g.add_node("x");
    g.add_node("y");
    g.add_link("x", "y");
    got = g.bloodline("y");
    exp: list[str] = ["x", "y"];
    assert got == exp;;
}
