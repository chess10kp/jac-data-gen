"""Guard: service-lasso/service-lasso#878."""

node Service {
    has sid: str;
    has endpoint: str = "";
    has stale: bool = False;
}

edge DependsOn {}

obj RuntimeGraph {
    has services: dict[str, Service] = {};

    def add_service(sid: str, endpoint: str) {
        nd = Service(sid=sid, endpoint=endpoint);
        root ++> nd;
        self.services[sid] = nd;
    }

    def link_depends(provider: str, consumer: str) {
        p = self.services.get(provider, None);
        c = self.services.get(consumer, None);
        if p is not None and c is not None { p +>:DependsOn:+> c; }
    }
}

walker ConsumerCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Service entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        visit [->:DependsOn:->][?:Service];
    }
}

def load_runtime_graph(
    services: list[str],
    depends: list[tuple[str, str]],
    endpoints: dict[str, str],
) -> RuntimeGraph {
    g = RuntimeGraph();
    for sid in services {
        g.add_service(sid, endpoints.get(sid, ""));
    }
    for (provider, consumer) in depends {
        g.link_depends(provider, consumer);
    }
    return g;
}

def impacted_consumers(graph: RuntimeGraph, provider_id: str) -> list[str] {
    start = graph.services.get(provider_id, None);
    if start is None { return []; }
    w = start spawn ConsumerCollect(claimed={}, found=[]);
    return sorted(
        sid for sid in w.found if sid != provider_id
    );
}

def propagate_endpoint(
    graph: RuntimeGraph,
    provider_id: str,
    new_value: str,
) -> list[str] {
    start = graph.services.get(provider_id, None);
    if start is None { raise KeyError("unknown provider"); }
    start.endpoint = new_value;
    rematerialized: list[str] = [provider_id];
    for sid in impacted_consumers(graph, provider_id) {
        nd = graph.services.get(sid, None);
        if nd is not None {
            nd.endpoint = new_value;
            nd.stale = True;
            rematerialized.append(sid);
        }
    }
    return sorted(rematerialized);
}

def active_endpoints(graph: RuntimeGraph) -> dict[str, str] {
    out: dict[str, str] = {};
    for k in sorted(graph.services.keys()) {
        nd = graph.services.get(k, None);
        if nd is not None { out[k] = nd.endpoint; }
    }
    return out;
}

test "endpoint cascade to consumers" {
    g = load_runtime_graph(
        ["api", "worker", "ui"],
        [("api", "worker"), ("api", "ui")],
        {"api": "8080", "worker": "8080", "ui": "8080"},
    );
    assert impacted_consumers(g, "api") == ["ui", "worker"];
    changed = propagate_endpoint(g, "api", "9090");
    assert changed == ["api", "ui", "worker"];
    assert active_endpoints(g) == {"api": "9090", "ui": "9090", "worker": "9090"};
}

test "solo provider only self rematerialized" {
    g = load_runtime_graph(["solo"], [], {"solo": "3000"});
    assert propagate_endpoint(g, "solo", "3001") == ["solo"];
}

test "unknown provider raises" {
    g = load_runtime_graph(["solo"], [], {"solo": "3000"});
    try {
        propagate_endpoint(g, "ghost", "1");
        assert False;
    } except KeyError {
        assert True;
    }
}

test "diamond fan-out consumers" {
    g = load_runtime_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
        {"hub": "1", "left": "1", "right": "1", "leaf": "1"},
    );
    assert impacted_consumers(g, "hub") == ["leaf", "left", "right"];
}
