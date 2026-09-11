"""Guard: frequenz-floss/frequenz-microgrid-component-graph-rs#49."""

node Meter { has mid: str; }
edge Feeds {}

obj MeterGraph {
    has meters: dict[str, Meter] = {};
}

walker ReachProbe {
    has targets: dict[str, bool] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can step with Meter entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if here.mid in self.targets { self.found = True; }
        visit [->:Feeds:->][?:Meter];
    }
}

def load_meter_graph(meters: list[str], feeds: list[tuple[str, str]]) -> MeterGraph {
    g = MeterGraph();
    for mid in meters {
        nd = Meter(mid=mid);
        root ++> nd;
        g.meters[mid] = nd;
    }
    for (src, dst) in feeds {
        s = g.meters.get(src, None);
        d = g.meters.get(dst, None);
        if s is not None and d is not None { s +>:Feeds:+> d; }
    }
    return g;
}

def reaches_any(graph: MeterGraph, start: str, targets: set[str]) -> bool {
    nd = graph.meters.get(start, None);
    if nd is None { return False; }
    tmap: dict[str, bool] = {};
    for t in targets { tmap[t] = True; }
    w = nd spawn ReachProbe(targets=tmap, claimed={}, found=False);
    return w.found;
}

def prune_topmost_candidates(graph: MeterGraph, candidates: list[str]) -> list[str] {
    ordered = sorted(candidates);
    keep: list[str] = [];
    for mid in ordered {
        dominated = False;
        for other in ordered {
            if other != mid and reaches_any(graph, other, {mid}) {
                dominated = True;
            }
        }
        if not dominated { keep.append(mid); }
    }
    return keep;
}

test "prune ancestor meters" {
    g = load_meter_graph(
        ["m1", "m2", "m3", "m4"],
        [("m1", "m2"), ("m2", "m3"), ("m1", "m4")],
    );
    assert prune_topmost_candidates(g, ["m1", "m2", "m3"]) == ["m1"];
}

test "parallel feeds keep topmost" {
    g = load_meter_graph(
        ["m1", "m2", "m3", "m4"],
        [("m1", "m2"), ("m2", "m3"), ("m1", "m4")],
    );
    assert prune_topmost_candidates(g, ["m2", "m3", "m4"]) == ["m2", "m4"];
}

test "diamond adversarial revisit" {
    g = load_meter_graph(
        ["hub", "left", "right", "leaf"],
        [("hub", "left"), ("hub", "right"), ("left", "leaf"), ("right", "leaf")],
    );
    assert sorted(prune_topmost_candidates(g, ["left", "right", "leaf"])) == [
        "left",
        "right",
    ];
}
