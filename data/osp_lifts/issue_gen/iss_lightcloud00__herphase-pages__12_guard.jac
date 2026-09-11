"""lightcloud00/herphase-pages#12 — canonical CycleKeep site routes and legacy redirect resolution."""

glob ROLE_CANONICAL = "canonical";
glob ROLE_MIRROR = "mirror";
glob ROLE_LEGACY = "legacy";

node SiteHost {
    has hid: str;
    has role: str;
    has indexed: bool;
}

node SiteRoute {
    has rid: str;
    has hid: str;
    has path: str;
    has status: int = 200;
}

edge Serves {}
edge RedirectsTo {}

obj SiteGraph {
    has hosts: dict[str, SiteHost] = {};
    has routes: dict[str, SiteRoute] = {};
}

walker RedirectWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has terminal: str = "";

    can step with SiteRoute entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.chain.append(here.rid);
        targets: list[SiteRoute] = [here ->:RedirectsTo:->][?:SiteRoute];
        if len(targets) == 0 {
            self.terminal = here.rid;
            disengage;
        }
        names: list[str] = [];
        for t in targets { names.append(t.rid); }
        names = sorted(names);
        ordered: list[SiteRoute] = [];
        for nm in names {
            for t in targets { if t.rid == nm { ordered.append(t); } }
        }
        i = len(ordered) - 1;
        while i >= 0 {
            visit :0: [ordered[i]];
            i -= 1;
        }
        if self.terminal == "" { self.terminal = here.rid; }
    }
}

def _route_key(hid: str, path: str) -> str {
    return hid + "::" + path;
}

def fresh_site_graph -> SiteGraph {
    return SiteGraph();
}

def register_host(hid: str, role: str, indexed: bool, store: SiteGraph | None = None) -> SiteGraph {
    s = store;
    if s is None { s = fresh_site_graph(); }
    if hid in s.hosts { raise ValueError("duplicate host"); }
    nd = SiteHost(hid=hid, role=role, indexed=indexed);
    root ++> nd;
    s.hosts[hid] = nd;
    return s;
}

def register_route(hid: str, path: str, status: int = 200, store: SiteGraph) -> str {
    if hid not in store.hosts { raise KeyError(hid); }
    rid = _route_key(hid, path);
    if rid in store.routes { raise ValueError("duplicate route"); }
    host = store.hosts[hid];
    nd = SiteRoute(rid=rid, hid=hid, path=path, status=status);
    root ++> nd;
    host +>:Serves:+> nd;
    store.routes[rid] = nd;
    return rid;
}

def add_path_redirect(from_hid: str, path: str, to_hid: str, store: SiteGraph) {
    from_rid = _route_key(from_hid, path);
    to_rid = _route_key(to_hid, path);
    if from_rid not in store.routes or to_rid not in store.routes {
        raise KeyError("unknown route");
    }
    src = store.routes[from_rid];
    dst = store.routes[to_rid];
    src +>:RedirectsTo:+> dst;
}

def redirect_chain(hid: str, path: str, store: SiteGraph) -> list[str] {
    rid = _route_key(hid, path);
    if rid not in store.routes { raise KeyError(rid); }
    nd = store.routes[rid];
    w = nd spawn RedirectWalk(claimed={}, chain=[], terminal="");
    return w.chain;
}

def terminal_route(hid: str, path: str, store: SiteGraph) -> dict {
    rid = _route_key(hid, path);
    if rid not in store.routes { raise KeyError(rid); }
    nd = store.routes[rid];
    w = nd spawn RedirectWalk(claimed={}, chain=[], terminal="");
    end_rid = w.terminal;
    if end_rid == "" { end_rid = w.chain[len(w.chain) - 1]; }
    end = store.routes[end_rid];
    return {"host": end.hid, "path": end.path, "status": end.status};
}

def count_indexed_duplicates(store: SiteGraph) -> int {
    n = 0;
    for hid in sorted(store.hosts.keys()) {
        host = store.hosts[hid];
        if host.indexed and host.role != ROLE_CANONICAL { n += 1; }
    }
    return n;
}

def proves_canonical_terminus(hid: str, path: str, store: SiteGraph) -> bool {
    term = terminal_route(hid, path, store);
    host = store.hosts.get(term["host"], None);
    if host is None { return False; }
    return host.role == ROLE_CANONICAL and term["status"] == 200;
}

test "diamond redirect closure skips revisit" {
    s = fresh_site_graph();
    register_host("gds", ROLE_CANONICAL, False, s);
    register_host("github.io", ROLE_MIRROR, False, s);
    register_host("herphase.app", ROLE_LEGACY, True, s);
    register_route("gds", "/hub/", 200, s);
    register_route("github.io", "/hub/", 200, s);
    register_route("herphase.app", "/hub/", 200, s);
    add_path_redirect("herphase.app", "/hub/", "github.io", s);
    add_path_redirect("github.io", "/hub/", "gds", s);
    add_path_redirect("github.io", "/hub/", "herphase.app", s);
    chain = redirect_chain("herphase.app", "/hub/", s);
    assert chain == ["herphase.app::/hub/", "github.io::/hub/", "gds::/hub/"];
    assert proves_canonical_terminus("herphase.app", "/hub/", s);
}

test "unknown route tolerance" {
    s = fresh_site_graph();
    register_host("gds", ROLE_CANONICAL, False, s);
    caught = False;
    try { redirect_chain("ghost", "/", s); } except KeyError { caught = True; }
    assert caught;
    try { terminal_route("gds", "/missing/", s); } except KeyError { caught = True; }
    assert caught;
}

test "path preserving redirect terminates at canonical 200" {
    s = fresh_site_graph();
    register_host("gds", ROLE_CANONICAL, False, s);
    register_host("github.io", ROLE_MIRROR, False, s);
    register_host("herphase.app", ROLE_LEGACY, True, s);
    register_route("gds", "/support/", 200, s);
    register_route("github.io", "/support/", 200, s);
    register_route("herphase.app", "/support/", 200, s);
    add_path_redirect("herphase.app", "/support/", "github.io", s);
    add_path_redirect("github.io", "/support/", "gds", s);
    term = terminal_route("herphase.app", "/support/", s);
    assert term == {"host": "gds", "path": "/support/", "status": 200};
    assert proves_canonical_terminus("herphase.app", "/support/", s);
}

test "legacy privacy 404 without redirect" {
    s = fresh_site_graph();
    register_host("gds", ROLE_CANONICAL, False, s);
    register_host("herphase.app", ROLE_LEGACY, True, s);
    register_route("gds", "/privacy/", 200, s);
    register_route("herphase.app", "/privacy/", 404, s);
    term = terminal_route("herphase.app", "/privacy/", s);
    assert term == {"host": "herphase.app", "path": "/privacy/", "status": 404};
    assert proves_canonical_terminus("herphase.app", "/privacy/", s) == False;
}

test "indexed duplicate hosts counted" {
    s = fresh_site_graph();
    register_host("gds", ROLE_CANONICAL, False, s);
    register_host("github.io", ROLE_MIRROR, False, s);
    register_host("herphase.app", ROLE_LEGACY, True, s);
    assert count_indexed_duplicates(s) == 1;
}
