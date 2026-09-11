"""frequenz-floss/frequenz-microgrid-component-graph-rs#49 — Prune topmost meter candidates."""

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
