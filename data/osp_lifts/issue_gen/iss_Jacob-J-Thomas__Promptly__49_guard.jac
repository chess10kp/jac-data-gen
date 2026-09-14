"""Synthetic release-bundle graph for Jacob-J-Thomas/Promptly#49."""

node Route {
    has name: str;
    has path: str;
    has lazy: bool = False;
}

node Chunk {
    has name: str;
    has raw_kb: int = 0;
    has gzip_kb: int = 0;
    has lazy: bool = False;
}

edge RouteLink {}
edge Includes {}

walker RouteScan {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can collect with Route entry {
        cid: str = here.cid;
        claims: dict[str, bool] = self.claimed;
        if cid in claims { skip; }
        claims[cid] = True;
        print(here.name);
        self.names.append(here.name);
        for kid in [here ->:RouteLink:->][?:Route] {
            visit :0: [kid];
        }
    }
}

walker InitialScan {
    has claimed: dict[str, bool] = {};
    has chunks: list[Chunk] = [];

    can scan_route with Route entry {
        cid: str = here.cid;
        claims: dict[str, bool] = self.claimed;
        if cid in claims { skip; }
        claims[cid] = True;
        print(here.name);
        for asset in [here ->:Includes:->][?:Chunk] {
            visit :0: [asset];
        }
        for kid in [here ->:RouteLink:->][?:Route] {
            if not kid.lazy {
                visit :0: [kid];
            }
        }
    }

    can scan_chunk with Chunk entry {
        cid: str = here.cid;
        claims: dict[str, bool] = self.claimed;
        if cid in claims { skip; }
        claims[cid] = True;
        print(here.name);
        if here.lazy { skip; }
        self.chunks.append(here);
    }
}

walker RouteFind {
    has claimed: dict[str, bool] = {};
    has wanted: str = "";
    has matched: bool = False;

    can find with Route entry {
        cid: str = here.cid;
        claims: dict[str, bool] = self.claimed;
        if cid in claims { skip; }
        claims[cid] = True;
        print(here.name);
        if here.name == self.wanted {
            self.matched = True;
            disengage;
        }
        for kid in [here ->:RouteLink:->][?:Route] {
            visit :0: [kid];
        }
    }
}

def route_manifest(graph_root: Route) -> list[str] {
    w = graph_root spawn RouteScan();
    return w.names;
}

def initial_chunks(graph_root: Route) -> list[Chunk] {
    w = graph_root spawn InitialScan();
    return w.chunks;
}

def initial_raw_kb(graph_root: Route) -> int {
    chunks: list[Chunk] = initial_chunks(graph_root);
    total: int = 0;
    for chunk in chunks {
        total += chunk.raw_kb;
    }
    return total;
}

def initial_gzip_kb(graph_root: Route) -> int {
    chunks: list[Chunk] = initial_chunks(graph_root);
    total: int = 0;
    for chunk in chunks {
        total += chunk.gzip_kb;
    }
    return total;
}

def within_budget(graph_root: Route, budget_kb: int = 500) -> bool {
    return initial_raw_kb(graph_root) <= budget_kb;
}

def has_route(graph_root: Route, wanted: str) -> bool {
    w = graph_root spawn RouteFind(wanted=wanted);
    return w.matched;
}

test "diamond closure and unknown route tolerance" {
    root_node = Route(name="home", path="/");
    left = Route(name="left", path="/left");
    right = Route(name="right", path="/right");
    shared = Route(name="shared", path="/shared");
    root_node +>:RouteLink:+> right;
    root_node +>:RouteLink:+> left;
    left +>:RouteLink:+> shared;
    right +>:RouteLink:+> shared;
    assert (sorted(route_manifest(root_node)) == ["home", "left", "right", "shared"]);
    assert (has_route(root_node, "shared"));
    assert (not has_route(root_node, "missing"));
}

test "lazy mapping and monaco stay outside initial budget" {
    root_node = Route(name="home", path="/");
    mapping = Route(name="mapping", path="/mapping", lazy=True);
    vendor = Chunk(name="vendor", raw_kb=220, gzip_kb=70);
    app = Chunk(name="app", raw_kb=180, gzip_kb=50);
    monaco = Chunk(name="monaco", raw_kb=300, gzip_kb=90, lazy=True);
    root_node +>:Includes:+> vendor;
    root_node +>:Includes:+> app;
    root_node +>:RouteLink:+> mapping;
    mapping +>:Includes:+> monaco;
    assert (len(initial_chunks(root_node)) == 2);
    assert (initial_raw_kb(root_node) == 400);
    assert (initial_gzip_kb(root_node) == 120);
    assert (within_budget(root_node, 500));
    assert (not within_budget(root_node, 399));
}

test "empty release graph has zero initial weight" {
    root_node = Route(name="empty", path="/empty");
    assert (route_manifest(root_node) == ["empty"]);
    assert (len(initial_chunks(root_node)) == 0);
    assert (initial_raw_kb(root_node) == 0);
    assert (initial_gzip_kb(root_node) == 0);
    assert (not has_route(root_node, "unknown"));
}

test "adversarial diamond deduplicates shared chunk" {
    root_node = Route(name="root", path="/");
    left = Route(name="left", path="/left");
    right = Route(name="right", path="/right");
    shared = Route(name="shared", path="/shared");
    common = Chunk(name="common", raw_kb=75, gzip_kb=25);
    root_node +>:RouteLink:+> right;
    root_node +>:RouteLink:+> left;
    left +>:RouteLink:+> shared;
    right +>:RouteLink:+> shared;
    shared +>:Includes:+> common;
    assert (len(initial_chunks(root_node)) == 1);
    assert (initial_raw_kb(root_node) == 75);
    assert (initial_gzip_kb(root_node) == 25);
}
