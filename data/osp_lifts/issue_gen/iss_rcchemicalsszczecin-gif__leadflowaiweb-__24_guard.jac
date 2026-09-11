"""rcchemicalsszczecin-gif/leadflowaiweb#24 — post-V15 legacy route CSS de-stack inventory."""

node Layer {
    has lid: str;
    has stack_ord: int = 0;
    has bridge_active: bool = True;
}

node Selector {
    has sid: str;
    has obsolete: bool = False;
    has superseded: bool = False;
}

node Rule {
    has rule_id: str;
}

node Route {
    has rid: str;
    has bridge_free: bool = False;
}

edge StackNext {}
edge Contains {}
edge Supersedes {}
edge RouteReach {}

def make_source_ids() -> list[str] {
    ids: list[str] = [];
    ids.append("app/services.css");
    ids.append("app/precision-water.css");
    ids.append("app/circuit-water-v3.css");
    ids.append("app/hardware-board-v4.css");
    ids.append("app/realistic-board-v5.css");
    ids.append("app/content-frames-v6.css");
    return ids;
}

def build_layer_stack() -> dict[str, Layer] {
    store: dict[str, Layer] = {};
    ids: list[str] = make_source_ids();
    ord_val: int = 0;
    prev_ly: Layer | None = None;
    for lid in ids {
        ly = Layer(lid=lid, stack_ord=ord_val, bridge_active=True);
        store[lid] = ly;
        root ++> ly;
        if prev_ly is not None {
            prev_ly +>:StackNext:+> ly;
        }
        prev_ly = ly;
        ord_val = ord_val + 1;
    }
    return store;
}

def seed_bridge_fixture(store: dict[str, Layer]) -> None {
    ly0 = store["app/services.css"];
    ly5 = store["app/content-frames-v6.css"];
    s_active = Selector(sid=".service-hero", obsolete=False, superseded=False);
    s_remove = Selector(sid=".renderer-gl-v2", obsolete=True, superseded=True);
    s_block = Selector(sid=".legacy-board-pin", obsolete=True, superseded=False);
    r_v14 = Rule(rule_id="v14-generic-card");
    ly0 +>:Contains:+> s_active;
    ly0 +>:Contains:+> s_remove;
    ly5 +>:Contains:+> s_block;
    s_remove +>:Supersedes:+> r_v14;
}

def layer_selector_inventory(store: dict[str, Layer], layer_id: str) -> list[str] {
    if layer_id not in store {
        empty: list[str] = [];
        return empty;
    }
    ly = store[layer_id];
    w = ly spawn LayerInventoryWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def classify_selector(store: dict[str, Layer], selector_id: str) -> str {
    ids: list[str] = make_source_ids();
    for lid in ids {
        if lid in store {
            ly = store[lid];
            for sel in [ly ->:Contains:->][?:Selector] {
                if sel.sid == selector_id {
                    if sel.obsolete {
                        if sel.superseded {
                            return "remove";
                        }
                        return "retain";
                    }
                    return "active";
                }
            }
        }
    }
    return "unknown";
}

def proven_removable_selectors(store: dict[str, Layer]) -> list[str] {
    out: list[str] = [];
    ids: list[str] = make_source_ids();
    for lid in ids {
        if lid in store {
            ly = store[lid];
            for sel in [ly ->:Contains:->][?:Selector] {
                if sel.obsolete and sel.superseded {
                    out.append(sel.sid);
                }
            }
        }
    }
    return sorted(out);
}

def build_route_fixture() -> dict[str, Route] {
    rstore: dict[str, Route] = {};
    home = Route(rid="/", bridge_free=True);
    svc = Route(rid="/services", bridge_free=False);
    know = Route(rid="/knowledge", bridge_free=False);
    hub = Route(rid="/hub", bridge_free=False);
    rstore["/"] = home;
    rstore["/services"] = svc;
    rstore["/knowledge"] = know;
    rstore["/hub"] = hub;
    home +>:RouteReach:+> svc;
    home +>:RouteReach:+> know;
    svc +>:RouteReach:+> hub;
    know +>:RouteReach:+> hub;
    root ++> home;
    return rstore;
}

def route_reachable(rstore: dict[str, Route], from_rid: str, to_rid: str) -> bool {
    if from_rid not in rstore {
        return False;
    }
    if to_rid not in rstore {
        return False;
    }
    start = rstore[from_rid];
    w = start spawn ReachWalker(claimed={}, target=to_rid, reached=False);
    return w.reached;
}

walker LayerInventoryWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can scan with Layer entry {
        if here.lid in self.claimed {
            skip;
        }
        self.claimed[here.lid] = True;
        print("inventory layer " + here.lid);
        for sel in [here ->:Contains:->][?:Selector] {
            self.found.append(sel.sid);
            print("selector " + sel.sid);
        }
        disengage;
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has reached: bool = False;

    can walk with Route entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        print("route " + here.rid);
        if here.rid == self.target {
            self.reached = True;
        }
        nbrs: list[Route] = [];
        for nxt in [here ->:RouteReach:->][?:Route] {
            nbrs.append(nxt);
        }
        if len(nbrs) > 0 {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

walker StackDemoWalker {
    has claimed: dict[str, bool] = {};

    can step with Layer entry {
        if here.lid in self.claimed {
            skip;
        }
        self.claimed[here.lid] = True;
        print("stack layer " + here.lid);
        kids: list[Layer] = [];
        for nxt in [here ->:StackNext:->][?:Layer] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

with entry {
    store = build_layer_stack();
    seed_bridge_fixture(store);
    root spawn StackDemoWalker(claimed={});
}

test "unknown layer inventory empty" {
    store = build_layer_stack();
    got = layer_selector_inventory(store, "app/missing-layer.css");
    assert len(got) == 0;
}

test "unknown selector classify tolerant" {
    store = build_layer_stack();
    seed_bridge_fixture(store);
    assert classify_selector(store, ".no-such-selector") == "unknown";
}

test "obsolete without replacement stays retain" {
    store = build_layer_stack();
    seed_bridge_fixture(store);
    assert classify_selector(store, ".legacy-board-pin") == "retain";
}

test "proven removable sorted multiset" {
    store = build_layer_stack();
    seed_bridge_fixture(store);
    got = proven_removable_selectors(store);
    assert got == [".renderer-gl-v2"];
}

test "diamond route revisit still reaches hub" {
    rstore = build_route_fixture();
    assert route_reachable(rstore, "/", "/hub") == True;
}

test "homepage bridge free unknown route false" {
    rstore = build_route_fixture();
    assert rstore["/"].bridge_free == True;
    assert route_reachable(rstore, "/", "/missing-route") == False;
}
