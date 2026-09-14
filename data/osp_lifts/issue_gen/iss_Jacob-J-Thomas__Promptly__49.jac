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
