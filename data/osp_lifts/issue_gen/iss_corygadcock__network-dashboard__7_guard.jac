"""corygadcock/network-dashboard#7 — candidate + hidden guards."""

obj TopoStore { has stamp: int = 0; }
node Device { has name: str; }
edge Cable {}

walker TraceGateway {
    has start: str;
    has gateway: str;
    has parent_map: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    def _visit_sorted_out() -> None {
        pending: list[str] = [];
        for n in [here ->:Cable:->][?:Device] {
            if n.name not in self.claimed { pending.append(n.name); }
        }
        pending.sort();
        for nm in pending {
            for n in [here ->:Cable:->][?:Device] {
                if n.name == nm { visit [n]; }
            }
        }
    }

    can begin with Device entry {
        if here.name != self.start { skip; }
        self.claimed[self.start] = True;
        if self.start == self.gateway { self.found = True; disengage; }
        self._visit_sorted_out();
    }

    can step with Device entry {
        if here.name in self.claimed { skip; }
        for p in [here <-:Cable:<-][?:Device] {
            if p.name in self.claimed {
                self.parent_map[here.name] = p.name;
                break;
            }
        }
        if here.name not in self.parent_map and here.name != self.start { skip; }
        self.claimed[here.name] = True;
        if here.name == self.gateway { self.found = True; disengage; }
        self._visit_sorted_out();
    }
}

def _device(name: str) -> Device | None {
    for d in [-->][?:Device] { if d.name == name { return d; } }
    return None;
}

def _wire(nodes: list[str], links: list[tuple[str, str]]) {
    mp: dict[str, Device] = {};
    for n in nodes {
        if n not in mp { d = Device(name=n); root ++> d; mp[n] = d; }
    }
    for (src, dst) in links {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is None or b is None { continue; }
        a +>:Cable:+> b;
    }
}

def _depth(parent: dict[str, str], `node: str, start: str) -> int {
    d = 0;
    cur: str | None = `node;
    while cur is not None and cur != start {
        d += 1;
        cur = parent.get(cur, None);
    }
    return d;
}

def _deepest(claimed: dict[str, bool], parent: dict[str, str], start: str) -> str {
    best = start;
    best_d = 0;
    for nm in claimed.keys() {
        d = _depth(parent, nm, start);
        if d > best_d { best_d = d; best = nm; }
    }
    return best;
}

def _reconstruct_path(parent: dict[str, str], end: str, start: str) -> list[str] {
    path: list[str] = [];
    cur: str | None = end;
    while cur is not None {
        path.append(cur);
        if cur == start { break; }
        cur = parent.get(cur, None);
    }
    path.reverse();
    return path;
}

def load_topology(nodes: list[str], links: list[tuple[str, str]]) -> TopoStore {
    _wire(nodes, links);
    return TopoStore(stamp=1);
}

def trace_to_gateway(
    store: TopoStore,
    start: str,
    gateway: str,
) -> tuple[list[str], str | None] {
    _ = store;
    sdev = _device(start);
    if sdev is None { return ([], "unknown_start"); }
    w = sdev spawn TraceGateway(
        start=start, gateway=gateway, parent_map={}, claimed={}, found=False,
    );
    if w.found {
        return (_reconstruct_path(w.parent_map, gateway, start), None);
    }
    deepest = _deepest(w.claimed, w.parent_map, start);
    return (
        _reconstruct_path(w.parent_map, deepest, start),
        "missing_documentation",
    );
}

test "full trace to gateway" {
    t = load_topology(
        ["host", "switch", "router", "gw"],
        [("host", "switch"), ("switch", "router"), ("router", "gw")],
    );
    (path, brk) = trace_to_gateway(t, "host", "gw");
    assert path == ["host", "switch", "router", "gw"];
    assert brk is None;
}

test "partial trace reports missing documentation" {
    t = load_topology(["a", "b", "c"], [("a", "b"), ("b", "c")]);
    (path, brk) = trace_to_gateway(t, "a", "gw");
    assert path == ["a", "b", "c"];
    assert brk == "missing_documentation";
}

test "unknown start tolerant" {
    t = load_topology(["only"], []);
    (path, brk) = trace_to_gateway(t, "nope", "only");
    assert path == [];
    assert brk == "unknown_start";
}

test "diamond tie-break uses sorted neighbor order" {
    # Links inserted so b-path is queued before a-path would win without sort;
    # sorted enqueue must still pick a->t (matches Python sorted adj).
    t = load_topology(
        ["s", "a", "b", "t"],
        [("s", "b"), ("s", "a"), ("b", "t"), ("a", "t")],
    );
    (path, brk) = trace_to_gateway(t, "s", "t");
    assert path == ["s", "a", "t"];
    assert brk is None;
}

test "cycle graph terminates via claim map" {
    t = load_topology(
        ["a", "b", "c", "gw"],
        [("a", "b"), ("b", "c"), ("c", "a"), ("c", "gw")],
    );
    (path, brk) = trace_to_gateway(t, "a", "gw");
    assert path == ["a", "b", "c", "gw"];
    assert brk is None;
}

test "start equals gateway" {
    t = load_topology(["gw"], []);
    (path, brk) = trace_to_gateway(t, "gw", "gw");
    assert path == ["gw"];
    assert brk is None;
}
