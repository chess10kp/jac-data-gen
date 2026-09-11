"""Shared-Reality-Lab/IMAGE-server#1020 — orchestrator output-vs-service dependency resolution."""

node ServiceNode {
    has name: str;
    has outputs: set[str] = set();
    has required: list[str] = [];
    has optional: list[str] = [];
    has active: bool = True;
}

edge Requires {}

obj OrchestratorRegistry {
    has services: dict[str, dict] = {};
    has _edges: dict[str, list[str]] = {};
    has _built: bool = False;
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with ServiceNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.hits.append(here.name); }
        prereqs = [here ->:Requires:->][?:ServiceNode];
        nms: list[str] = [];
        for n in prereqs { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in prereqs {
                if n.name == nm {
                    n spawn UpstreamWalk(
                        claimed=self.claimed,
                        hits=self.hits,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker KahnGraphWalk {
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];
    has active: set[str] = set();
    has rev: dict[str, list[str]] = {};

    can begin with Root entry {
        nodes = [root -->][?:ServiceNode];
        for nd in nodes {
            if nd.name not in self.active { continue; }
            self.indeg[nd.name] = 0;
        }
        for nd in nodes {
            if nd.name not in self.active { continue; }
            prereqs = [nd ->:Requires:->][?:ServiceNode];
            self.indeg[nd.name] = len(prereqs);
            for dep in prereqs {
                if dep.name not in self.rev { self.rev[dep.name] = []; }
                self.rev[dep.name].append(nd.name);
            }
        }
        rev_keys: list[str] = [];
        for k in self.rev.keys() { rev_keys.append(k); }
        for k in rev_keys {
            uniq: list[str] = [];
            for x in self.rev[k] {
                if x not in uniq { uniq.append(x); }
            }
            self.rev[k] = sorted(uniq);
        }
        seed: list[str] = [];
        for nd in nodes {
            if nd.name not in self.active { continue; }
            if self.indeg.get(nd.name, 0) == 0 { seed.append(nd.name); }
        }
        self.ready = sorted(seed);
        while len(self.ready) > 0 {
            cur = self.ready[0];
            rest: list[str] = [];
            idx = 1;
            while idx < len(self.ready) {
                rest.append(self.ready[idx]);
                idx += 1;
            }
            self.ready = rest;
            self.order.append(cur);
            for nm in sorted(self.rev.get(cur, [])) {
                self.indeg[nm] = self.indeg.get(nm, 0) - 1;
                if self.indeg[nm] == 0 { self.ready.append(nm); }
            }
            self.ready = sorted(self.ready);
        }
        report self.order;
    }
}

def create_registry() -> OrchestratorRegistry {
    return OrchestratorRegistry();
}

def _find_service(name: str) -> ServiceNode | None {
    for nd in [root -->][?:ServiceNode] {
        if nd.name == name { return nd; }
    }
    return None;
}

def _clear_requires_edges() -> None {
    for nd in [root -->][?:ServiceNode] {
        for tgt in [nd ->:Requires:->][?:ServiceNode] {
            for e in [edge nd ->:Requires:-> tgt] { del e; }
        }
    }
}

def _provider_index(reg: OrchestratorRegistry) -> dict[str, list[str]] {
    idx: dict[str, list[str]] = {};
    keys: list[str] = [];
    for k in reg.services.keys() { keys.append(k); }
    for svc in sorted(keys) {
        meta = reg.services[svc];
        if not meta["active"] { continue; }
        outs: set[str] = meta["outputs"] as set[str];
        out_keys: list[str] = [];
        for o in outs { out_keys.append(o); }
        for out in sorted(out_keys) {
            if out not in idx { idx[out] = []; }
            providers = idx[out];
            if svc not in providers { providers.append(svc); }
        }
    }
    result: dict[str, list[str]] = {};
    for (out, providers) in idx.items() {
        result[out] = sorted(providers);
    }
    return result;
}

def _resolve_label(
    reg: OrchestratorRegistry,
    label: str,
    providers: dict[str, list[str]],
) -> str | None {
    meta = reg.services.get(label, None);
    if meta is not None and meta["active"] {
        return label;
    }
    choices = providers.get(label, []);
    if len(choices) > 0 {
        return choices[0];
    }
    return None;
}

def register_service(
    reg: OrchestratorRegistry,
    name: str,
    outputs: list[str] | None = None,
    required: list[str] | None = None,
    optional: list[str] | None = None,
    active: bool = True,
) -> None {
    outs: set[str] = set();
    if outputs is not None {
        for o in outputs { outs.add(o); }
    }
    req: list[str] = [];
    if required is not None {
        for r in required { req.append(r); }
    }
    opt: list[str] = [];
    if optional is not None {
        for o in optional { opt.append(o); }
    }
    reg.services[name] = {
        "outputs": outs,
        "required": req,
        "optional": opt,
        "active": active,
    };
    nd = _find_service(name);
    if nd is None {
        nd = ServiceNode(
            name=name,
            outputs=outs,
            required=req,
            optional=opt,
            active=active,
        );
        root ++> nd;
    } else {
        nd.outputs = outs;
        nd.required = req;
        nd.optional = opt;
        nd.active = active;
    }
    reg._built = False;
}

def build_dependency_graph(reg: OrchestratorRegistry) -> dict[str, list[str]] {
    providers = _provider_index(reg);
    _clear_requires_edges();
    adj: dict[str, list[str]] = {};
    keys: list[str] = [];
    for k in reg.services.keys() { keys.append(k); }
    for svc in keys {
        meta = reg.services[svc];
        if not meta["active"] { continue; }
        prereqs: list[str] = [];
        req_list: list[str] = meta["required"] as list[str];
        for label in req_list {
            resolved = _resolve_label(reg, label, providers);
            if resolved is not None and resolved != svc and resolved not in prereqs {
                prereqs.append(resolved);
            }
        }
        adj[svc] = sorted(prereqs);
        snd = _find_service(svc);
        if snd is not None {
            for dep_nm in prereqs {
                dnd = _find_service(dep_nm);
                if dnd is not None { snd +>:Requires:+> dnd; }
            }
        }
    }
    reg._edges = adj;
    reg._built = True;
    return adj;
}

def output_providers(reg: OrchestratorRegistry, output_id: str) -> list[str] {
    return list(_provider_index(reg).get(output_id, []));
}

def execution_order(reg: OrchestratorRegistry) -> list[str] | None {
    adj = reg._edges;
    if not reg._built { adj = build_dependency_graph(reg); }
    active: set[str] = set();
    for k in adj.keys() { active.add(k); }
    w = root spawn KahnGraphWalk(
        order=[],
        indeg={},
        ready=[],
        active=active,
        rev={},
    );
    got = w.reports[0] if w.reports else [];
    if len(got) != len(adj) { return None; }
    return got;
}

def upstream_services(reg: OrchestratorRegistry, service: str) -> list[str] {
    adj = reg._edges;
    if not reg._built { adj = build_dependency_graph(reg); }
    if service not in adj { return []; }
    nd = _find_service(service);
    if nd is None { return []; }
    w = nd spawn UpstreamWalk(claimed={}, hits=[], origin=service);
    return sorted(w.hits);
}

def has_execution_cycle(reg: OrchestratorRegistry) -> bool {
    return execution_order(reg) is None;
}

test "diamond revisit upstream walk transitive closure" {
    reg = create_registry();
    register_service(reg, "base");
    register_service(reg, "left", required=["base"]);
    register_service(reg, "right", required=["base"]);
    register_service(reg, "join", required=["left", "right"]);
    build_dependency_graph(reg);
    assert upstream_services(reg, "join") == ["base", "left", "right"];;
    assert upstream_services(reg, "left") == ["base"];;
    assert upstream_services(reg, "right") == ["base"];;
    assert upstream_services(reg, "base") == [];;
}

test "unknown id tolerance across resolve upstream and providers" {
    reg = create_registry();
    register_service(reg, "solo", required=["missing_output", "ghost_svc"]);
    register_service(reg, "ghost_svc", active=False);
    build_dependency_graph(reg);
    assert reg._edges["solo"] == [];;
    assert upstream_services(reg, "absent") == [];;
    assert output_providers(reg, "missing_output") == [];;
    assert execution_order(reg) == ["solo"];;
}

test "output label defers to active service name over provider" {
    reg = create_registry();
    register_service(reg, "token");
    register_service(reg, "maker", outputs=["token"]);
    register_service(reg, "sink", required=["token"]);
    adj = build_dependency_graph(reg);
    assert adj["sink"] == ["token"];;
    assert adj["maker"] == [];;
    assert adj["token"] == [];;
}

test "lex first output provider when label is not a service" {
    reg = create_registry();
    register_service(reg, "zebra", outputs=["shared"]);
    register_service(reg, "alpha", outputs=["shared"]);
    register_service(reg, "consumer", required=["shared"]);
    adj = build_dependency_graph(reg);
    assert adj["consumer"] == ["alpha"];;
    assert output_providers(reg, "shared") == ["alpha", "zebra"];;
}

test "execution cycle rejects topo order" {
    reg = create_registry();
    register_service(reg, "a", required=["b"]);
    register_service(reg, "b", required=["a"]);
    assert execution_order(reg) is None;;
    assert has_execution_cycle(reg) == True;;
}

test "lex tie break and duplicate prereq collapse" {
    reg = create_registry();
    register_service(reg, "z_root");
    register_service(reg, "a_root");
    register_service(reg, "m_root");
    register_service(reg, "base", outputs=["x"]);
    register_service(reg, "fan", required=["base", "base", "fan"]);
    assert execution_order(reg) == ["a_root", "base", "fan", "m_root", "z_root"];;
    assert build_dependency_graph(reg)["fan"] == ["base"];;
}
