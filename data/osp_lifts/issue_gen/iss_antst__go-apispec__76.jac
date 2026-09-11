"""antst/go-apispec#76 — Gin call-graph reachability for OpenAPI path export."""

obj CallGraph {
    has handlers: dict[str, Handler] = {};
    has entries: list[str] = [];
}

node Handler { has name: str; }
node Route { has path: str; }

edge Calls {}
edge Registers {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Handler entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Calls:->] else { disengage; };
    }
}

def load_callgraph(
    handlers: list[str],
    calls: list[tuple[str, str]],
    routes: list[tuple[str, str]],
    entries: list[str],
) -> CallGraph {
    mp: dict[str, Handler] = {};
    for h in handlers {
        hnd = Handler(name=h);
        root ++> hnd;
        mp[h] = hnd;
    }
    for (src, dst) in calls {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None { a +>:Calls:+> b; }
    }
    for (handler, path) in routes {
        h = mp.get(handler, None);
        if h is not None {
            r = Route(path=path);
            root ++> r;
            h +>:Registers:+> r;
        }
    }
    return CallGraph(handlers=mp, entries=entries);
}

def reachable_handlers(g: CallGraph, `entry: str) -> list[str] {
    anchor = g.handlers.get(`entry, None);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def exported_paths(g: CallGraph) -> list[str] {
    reachable: list[str] = [];
    for ent in g.entries {
        for h in reachable_handlers(g, ent) {
            if h not in reachable { reachable.append(h); }
        }
    }
    paths: list[str] = [];
    for hname in sorted(reachable) {
        anchor = g.handlers.get(hname, None);
        if anchor is None { continue; }
        for r in [anchor ->:Registers:->][?:Route] { paths.append(r.path); }
    }
    return sorted(paths);
}
