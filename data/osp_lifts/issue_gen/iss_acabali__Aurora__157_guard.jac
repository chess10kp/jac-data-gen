"""acabali/Aurora#157 — canonical operational state tree reachability and reconciliation."""

glob CANONICAL_MAIN = "8b3293d168bd65ad053330e53695d50a73d552ad";
glob PR194_HEAD = "d96036ff609e0cac98f6c81a9474185e51b4f500";
glob DETACHED = "3c213f0ea8f005260d90b243b8cac2cb1731833d";

node StateRoot {}

node StateNode {
    has sid: str;
    has node_status: str = "UNKNOWN";
}

edge StateChild: StateNode --> StateNode {}

obj StateHandle {
    has root_nd: StateRoot;
    has status_by_id: dict[str, str] = {};

    def init {
        self.status_by_id = {};
        self.root_nd = StateRoot();
        root ++> self.root_nd;
        self._wire();
    }

    def _node(sid: str, st: str) -> StateNode {
        nd = StateNode(sid=sid, node_status=st);
        self.root_nd ++> nd;
        self.status_by_id[sid] = st;
        return nd;
    }

    def _link(src: StateNode, dst: StateNode) {
        src +>:StateChild():+> dst;
    }

    def _wire {
        repo = self._node("repo", "PUBLIC");
        main = self._node("main", "RESIDUAL_PII");
        pr194 = self._node("pr194", "SOURCE_GATES_GREEN");
        detached = self._node("detached", "TREE_EQUIVALENT");
        privacy = self._node("privacy_suite", "10/10_PASS");
        lead = self._node("lead_pipeline", "ACTIVE_EXPOSURE");
        self._link(repo, main);
        self._link(repo, pr194);
        self._link(repo, detached);
        self._link(pr194, privacy);
        self._link(main, lead);
    }

    def find_node(sid: str) -> StateNode | None {
        for nd in [self.root_nd -->][?:StateNode] {
            if nd.sid == sid { return nd; }
        }
        return None;
    }
}

def sort_states(items: list[StateNode]) -> list[StateNode] {
    names: list[str] = [];
    for it in items { names.append(it.sid); }
    names = sorted(names);
    out: list[StateNode] = [];
    for nm in names {
        for it in items {
            if it.sid == nm { out.append(it); }
        }
    }
    return out;
}

def _fresh_state() -> StateHandle { return StateHandle(); }

walker StateReach {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can go with StateNode entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.names.append(here.sid);
        kids = sort_states([here ->:StateChild:->]);
        for kid in kids { visit [kid]; }
    }
}

def path_to_root(node_id: str, state: StateHandle | None = None) -> list[str] {
    s = state;
    if s is None { s = _fresh_state(); }
    nd = s.find_node(node_id);
    if nd is None { raise KeyError(node_id); }
    chain: list[str] = [];
    cur: StateNode | None = nd;
    while cur is not None {
        chain.append(cur.sid);
        parents = [cur <-:StateChild:<-];
        if len(parents) > 0 { cur = parents[0]; }
        else { cur = None; }
    }
    chain.reverse();
    return chain;
}

def reachable_status_nodes(from_id: str, state: StateHandle | None = None) -> list[str] {
    s = state;
    if s is None { s = _fresh_state(); }
    nd = s.find_node(from_id);
    if nd is None { raise KeyError(from_id); }
    w = nd spawn StateReach(claimed={}, names=[]);
    return sorted(w.names);
}

def reconciliation_delta(base: str, candidate: str, state: StateHandle | None = None) -> dict {
    s = state;
    if s is None { s = _fresh_state(); }
    base_path = path_to_root(base, s);
    cand_path = path_to_root(candidate, s);
    base_set: dict[str, bool] = {};
    cand_set: dict[str, bool] = {};
    for x in base_path { base_set[x] = True; }
    for x in cand_path { cand_set[x] = True; }
    shared: list[str] = [];
    base_only: list[str] = [];
    cand_only: list[str] = [];
    for x in sorted(base_set.keys()) {
        if x in cand_set { shared.append(x); }
        else { base_only.append(x); }
    }
    for x in sorted(cand_set.keys()) {
        if x not in base_set { cand_only.append(x); }
    }
    base_status = s.status_by_id.get(base, "UNKNOWN");
    cand_status = s.status_by_id.get(candidate, "UNKNOWN");
    return {
        "shared_ancestors": shared,
        "base_only": base_only,
        "candidate_only": cand_only,
        "base_status": base_status,
        "candidate_status": cand_status,
    };
}

def blocking_issues(state: StateHandle | None = None) -> list[str] {
    s = state;
    if s is None { s = _fresh_state(); }
    issues: list[str] = [];
    if s.status_by_id.get("main", "") == "RESIDUAL_PII" {
        issues.append("main:residual_pii");
    }
    if s.status_by_id.get("lead_pipeline", "") == "ACTIVE_EXPOSURE" {
        issues.append("lead_pipeline:active_exposure");
    }
    if s.status_by_id.get("pr194", "") == "SOURCE_GATES_GREEN"
        and s.status_by_id.get("main", "") != "INTEGRATED" {
        issues.append("pr194:not_integrated");
    }
    return sorted(issues);
}

def canonical_refs(state: StateHandle | None = None) -> dict[str, str] {
    return {
        "main": CANONICAL_MAIN,
        "pr194": PR194_HEAD,
        "detached": DETACHED,
    };
}

test "reachable_status_nodes unknown from_id raises KeyError" {
    raised = False;
    try {
        reachable_status_nodes("ghost");
        assert False, "should have raised";
    } except KeyError {
        raised = True;
    }
    assert raised;;
}

test "reconciliation_delta unknown candidate raises KeyError" {
    raised = False;
    try {
        reconciliation_delta("main", "missing");
        assert False, "should have raised";
    } except KeyError {
        raised = True;
    }
    assert raised;;
}

test "StateReach claim-map dedups triple branch fan-out with adversarial wire order" {
    h = _fresh_state();
    repo_nd = h.find_node("repo");
    w = repo_nd spawn StateReach(claimed={}, names=[]);
    assert sorted(w.names) == [
        "detached",
        "lead_pipeline",
        "main",
        "pr194",
        "privacy_suite",
        "repo",
    ];;
    dup_free: dict[str, bool] = {};
    for nm in w.names {
        assert nm not in dup_free;;
        dup_free[nm] = True;
    }
}

test "reachable_status_nodes scoped closure excludes sibling branches" {
    assert reachable_status_nodes("main") == ["lead_pipeline", "main"];;
    assert reachable_status_nodes("detached") == ["detached"];;
}

test "reconciliation_delta cross-branch splits divergent subtrees" {
    delta = reconciliation_delta("main", "privacy_suite");
    assert delta["shared_ancestors"] == ["repo"];;
    assert delta["base_only"] == ["main"];;
    assert delta["candidate_only"] == ["pr194", "privacy_suite"];;
    assert delta["base_status"] == "RESIDUAL_PII";;
    assert delta["candidate_status"] == "10/10_PASS";;
}

test "blocking_issues clears blockers when statuses reconciled" {
    s = _fresh_state();
    s.status_by_id["main"] = "INTEGRATED";
    s.status_by_id["lead_pipeline"] = "SAFE";
    assert blocking_issues(s) == [];;
}
