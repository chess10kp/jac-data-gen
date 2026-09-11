"""1btc-news/news-client#33 — Agent workflow DAG for quantum beat deliverables."""

node AgentRole {
    has name: str;
    has status: str = "pending";
}

edge Requires {}

obj WorkflowStore {
    has roles: dict[str, AgentRole] = {};
}

walker PrereqWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with AgentRole entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        visit [->:Requires:->][?:AgentRole];
    }
}

def load_workflow(
    role_names: list[str],
    require_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> WorkflowStore {
    store = WorkflowStore();
    for role in role_names {
        nd = AgentRole(name=role);
        root ++> nd;
        store.roles[role] = nd;
    }
    for (upstream, downstream) in require_edges {
        u = store.roles.get(upstream, None);
        d = store.roles.get(downstream, None);
        if u is not None and d is not None { d +>:Requires:+> u; }
    }
    if status is not None {
        for (k, v) in status.items() {
            r = store.roles.get(k, None);
            if r is not None { r.status = v; }
        }
    }
    return store;
}

def ready_roles(store: WorkflowStore) -> list[str] {
    out: list[str] = [];
    for name in sorted(store.roles.keys()) {
        r = store.roles[name];
        if r.status != "pending" { continue; }
        deps_ok = True;
        for dep in [r ->:Requires:->][?:AgentRole] {
            if dep.status != "done" { deps_ok = False; break; }
        }
        if deps_ok { out.append(name); }
    }
    return out;
}

def prerequisite_chain(store: WorkflowStore, role: str) -> list[str] {
    nd = store.roles.get(role, None);
    if nd is None { return []; }
    w = nd spawn PrereqWalk(claimed={}, anchor=role);
    return sorted(w.found);
}

def mark_done(store: WorkflowStore, role: str) -> list[str] {
    nd = store.roles.get(role, None);
    if nd is None { return []; }
    nd.status = "done";
    return ready_roles(store);
}
