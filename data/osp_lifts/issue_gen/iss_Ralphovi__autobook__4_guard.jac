"""Guard: Ralphovi/autobook#4."""

obj BookingStore { has stamp: int = 0; }
node Booking { has bid: str; }
edge SeriesChild {}
edge ScheduleBefore {}

def _find(bid: str) -> Booking | None {
    for b in [-->][?:Booking] { if b.bid == bid { return b; } }
    return None;
}

def load_booking_store(
    series_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
) -> BookingStore {
    mp: dict[str, Booking] = {};
    for (parent, child) in series_edges {
        for bid in [parent, child] {
            if bid not in mp { nd = Booking(bid=bid); root ++> nd; mp[bid] = nd; }
        }
        p = mp.get(parent, None); c = mp.get(child, None);
        if p is not None and c is not None { p +>:SeriesChild:+> c; }
    }
    for (a, b) in depends_edges {
        for bid in [a, b] {
            if bid not in mp { nd = Booking(bid=bid); root ++> nd; mp[bid] = nd; }
        }
        x = mp.get(a, None); y = mp.get(b, None);
        if x is not None and y is not None { x +>:ScheduleBefore:+> y; }
    }
    return BookingStore(stamp=1);
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with Booking entry {
        if here.bid in self.claimed { skip; }
        self.claimed[here.bid] = True;
        self.reached.append(here.bid);
        visit [->:SeriesChild:->] else { disengage; };
    }
}

def instance_lineage(store: BookingStore, series_id: str) -> list[str] {
    _ = store;
    anchor = _find(series_id);
    if anchor is None { return []; }
    w = anchor spawn LineageWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def schedule_order(store: BookingStore) -> list[str] {
    _ = store;
    indeg: dict[str, int] = {};
    for b in [-->][?:Booking] { indeg[b.bid] = len([b ->:ScheduleBefore:->][?:Booking]); }
    out: list[str] = [];
    ready = sorted([nm for (nm, d) in indeg.items() if d == 0]);
    while ready {
        out += ready;
        nxt: list[str] = [];
        for nm in ready {
            cur = _find(nm);
            if cur is None { continue; }
            for dep in [cur <-:ScheduleBefore:<-][?:Booking] {
                indeg[dep.bid] -= 1;
                if indeg[dep.bid] == 0 { nxt.append(dep.bid); }
            }
        }
        ready = sorted(nxt);
    }
    return out if len(out) == len(indeg) else [];
}

def expand_occurrences(store: BookingStore, series_id: str, limit: int) -> list[str] {
    lineage = instance_lineage(store, series_id);
    order = schedule_order(store);
    ranked = sorted(lineage, key=lambda x: (order.index(x) if x in order else 10 ** 9, x));
    return ranked[: max(0, limit)];
}

test "lineage and schedule" {
    g = load_booking_store(
        [("weekly", ["w1", "w2"]), ("w1", []), ("w2", [])],
        [("w1", "w2")],
    );
    assert instance_lineage(g, "weekly") == ["w1", "w2", "weekly"];
    assert schedule_order(g) == ["weekly", "w1", "w2"];
    assert expand_occurrences(g, "weekly", 2) == ["weekly", "w1"];
}

test "diamond adversarial revisit" {
    g = load_booking_store(
        [("hub", ["a", "b"]), ("a", ["leaf"]), ("b", ["leaf"]), ("leaf", [])],
        [("hub", "a"), ("hub", "b")],
    );
    assert instance_lineage(g, "hub") == ["a", "b", "hub", "leaf"];
    assert expand_occurrences(g, "hub", 10) == ["hub", "a", "b", "leaf"];
}

test "unknown series" {
    g = load_booking_store([("x", [])], []);
    assert instance_lineage(g, "ghost") == [];
}
