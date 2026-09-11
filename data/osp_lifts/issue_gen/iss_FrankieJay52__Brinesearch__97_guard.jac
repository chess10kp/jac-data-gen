"""FrankieJay52/Brinesearch#97 — road junction connectivity via BFS."""

node Road {
    has rid: str;
}

node Junction {
    has jid: str;
}

edge AtJunction {}

edge JunctionLink {}

obj RoadGraph {
    has roads: dict[str, Road] = {};
    has junctions: dict[str, Junction] = {};
}

walker RoadReach {
    has claimed_roads: dict[str, bool] = {};
    has claimed_junctions: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can road_hop with Road entry {
        if here.rid in self.claimed_roads { skip; }
        self.claimed_roads[here.rid] = True;
        if here.rid != self.anchor { self.found.append(here.rid); }
        visit [->:AtJunction:->][?:Junction];
    }

    can junction_hop with Junction entry {
        if here.jid in self.claimed_junctions { skip; }
        self.claimed_junctions[here.jid] = True;
        visit [<-:AtJunction:<-][?:Road];
        visit [->:JunctionLink:->][?:Junction];
    }
}

def load_road_graph(
    roads: list[str],
    junctions: list[str],
    road_junction_edges: list[tuple[str, str]],
    junction_link_edges: list[tuple[str, str]] | None = None,
) -> RoadGraph {
    g = RoadGraph();
    for rid in roads {
        rd = Road(rid=rid);
        root ++> rd;
        g.roads[rid] = rd;
    }
    for jid in junctions {
        jn = Junction(jid=jid);
        root ++> jn;
        g.junctions[jid] = jn;
    }
    for (road, junction) in road_junction_edges {
        r = g.roads.get(road, None);
        j = g.junctions.get(junction, None);
        if r is not None and j is not None { r +>:AtJunction:+> j; }
    }
    if junction_link_edges is not None {
        for (j1, j2) in junction_link_edges {
            ja = g.junctions.get(j1, None);
            jb = g.junctions.get(j2, None);
            if ja is not None and jb is not None {
                ja +>:JunctionLink:+> jb;
                jb +>:JunctionLink:+> ja;
            }
        }
    }
    return g;
}

def connected_roads(store: RoadGraph, road_id: str) -> list[str] {
    nd = store.roads.get(road_id, None);
    if nd is None { return []; }
    w = nd spawn RoadReach(anchor=road_id);
    return sorted(w.found);
}

def junction_reach(store: RoadGraph, junction_id: str) -> list[str] {
    nd = store.junctions.get(junction_id, None);
    if nd is None { return []; }
    w = nd spawn RoadReach(anchor="");
    out: list[str] = [];
    for jid in w.claimed_junctions.keys() {
        if jid != junction_id { out.append(jid); }
    }
    for rid in w.claimed_roads.keys() { out.append(rid); }
    return sorted(out);
}

def road_component_size(store: RoadGraph, road_id: str) -> int {
    if road_id not in store.roads { return 0; }
    return 1 + len(connected_roads(store, road_id));
}

test "road junction reach" {
    g = load_road_graph(
        ["r1", "r2", "r3", "r4"],
        ["j1", "j2", "j3"],
        [("r1", "j1"), ("r2", "j1"), ("r2", "j2"), ("r3", "j2"), ("r4", "j3")],
        junction_link_edges=[("j2", "j3")],
    );
    assert connected_roads(g, "r1") == ["r2", "r3", "r4"];
    assert road_component_size(g, "r1") == 4;
}

test "junction diamond revisit" {
    g = load_road_graph(
        ["ra", "rb", "rc"],
        ["jx", "jy", "jz"],
        [("ra", "jx"), ("rb", "jx"), ("rb", "jy"), ("rc", "jy"), ("rc", "jz")],
        junction_link_edges=[("jx", "jy"), ("jy", "jz")],
    );
    assert connected_roads(g, "ra") == ["rb", "rc"];
}
