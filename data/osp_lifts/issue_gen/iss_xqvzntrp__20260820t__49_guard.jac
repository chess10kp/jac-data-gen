"""xqvzntrp/20260820t#49 — Execution orchestration over verified model closure."""

node ExecModel {
    has name: str;
    has output: str;
}

edge DependsOn {}

class CycleError(Exception) {}

obj ExecStore {
    has models: dict[str, ExecModel] = {};
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with ExecModel entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        visit [->:DependsOn:->][?:ExecModel];
    }
}

def load_execution(
    model_names: list[str],
    depends_edges: list[tuple[str, str]],
    outputs: dict[str, str] | None = None,
) -> ExecStore {
    store = ExecStore();
    for name in model_names {
        nd = ExecModel(name=name, output=name);
        root ++> nd;
        store.models[name] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = store.models.get(upstream, None);
        d = store.models.get(downstream, None);
        if u is not None and d is not None { d +>:DependsOn:+> u; }
    }
    if outputs is not None {
        for (k, v) in outputs.items() {
            m = store.models.get(k, None);
            if m is not None { m.output = v; }
        }
    }
    return store;
}

def execution_order(store: ExecStore) -> list[str] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for name in store.models {
        indegree[name] = 0;
        rev[name] = [];
    }
    for name in store.models {
        nd = store.models[name];
        for up in [nd ->:DependsOn:->][?:ExecModel] {
            indegree[name] += 1;
            rev[up.name].append(name);
        }
    }
    order: list[str] = [];
    ready: list[str] = [];
    for name in store.models {
        if indegree[name] == 0 { ready.append(name); }
    }
    pending = len(store.models);
    while pending > 0 {
        if len(ready) == 0 { raise CycleError("cycle in execution graph"); }
        ready.sort();
        nxt = ready[0];
        ready = ready[1:];
        order.append(nxt);
        pending -= 1;
        for other in rev.get(nxt, []) {
            indegree[other] -= 1;
            if indegree[other] == 0 { ready.append(other); }
        }
    }
    return order;
}

def upstream_closure(store: ExecStore, model: str) -> list[str] {
    nd = store.models.get(model, None);
    if nd is None { return []; }
    w = nd spawn UpstreamWalk(claimed={}, anchor=model);
    return sorted(w.found);
}

def bind_output(store: ExecStore, model: str) -> str {
    nd = store.models.get(model, None);
    if nd is None { return ""; }
    return nd.output;
}

test "execution order" {
    g = load_execution(
        ["scalar", "filter", "project", "join"],
        [("scalar", "filter"), ("filter", "project"), ("scalar", "join")],
        {"project": "out_project"},
    );
    assert execution_order(g) == ["scalar", "filter", "join", "project"];
}
