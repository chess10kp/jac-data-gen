// Lineage identity, SCC materialize-once, and termination checks (tsz-org/tsz#14351).

obj LineageStore {
    has stamp: int = 0;
    has alias_map: dict[str, str] = {};
    has scc_cache: list[list[str]] | None = None;
}

node Dep {
    has dep_id: str;
}

edge Depends {}

def _scc_head(comp: list[str]) -> str {
    return comp[0];
}

walker FindDep {
    has target: str;
    has reports: list[Dep] = [];

    can search with Root entry {
        visit [-->][?:Dep];
    }

    can pick with Dep entry {
        if here.dep_id == self.target {
            report here;
            disengage;
        }
        visit [-->];
    }
}

walker ForwardReach {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    has reports: list[list[str]] = [];

    can start with Dep entry {
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.acc.append(here.dep_id);
        visit [-->][?:Dep] else {
            disengage;
        };
    }

    can step with Dep entry {
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.acc.append(here.dep_id);
        visit [-->][?:Dep] else {
            disengage;
        };
    }

    can finish with Dep exit {
        report self.acc;
    }
}

walker BackwardReach {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    has reports: list[list[str]] = [];

    can start with Dep entry {
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.acc.append(here.dep_id);
        visit [<--][?:Dep] else {
            disengage;
        };
    }

    can step with Dep entry {
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.acc.append(here.dep_id);
        visit [<--][?:Dep] else {
            disengage;
        };
    }

    can finish with Dep exit {
        report self.acc;
    }
}

walker MaterializeSccs {
    has claimed: dict[str, bool] = {};
    has sccs: list[list[str]] = [];
    has reports: list[list[list[str]]] = [];

    can start with Root entry {
        visit [-->][?:Dep];
    }

    can collect with Dep entry {
        if here.dep_id in self.claimed {
            skip;
        }
        fwd_r = here spawn ForwardReach();
        bwd_r = here spawn BackwardReach();
        fwd = fwd_r.reports[0] if fwd_r.reports else [];
        bwd = bwd_r.reports[0] if bwd_r.reports else [];
        fwd_set: dict[str, bool] = {};
        for n in fwd {
            fwd_set[n] = True;
        }
        comp: list[str] = [];
        for n in bwd {
            if n in fwd_set {
                comp.append(n);
            }
        }
        comp = sorted(comp);
        for n in comp {
            self.claimed[n] = True;
        }
        self.sccs.append(comp);
        visit [-->];
    }

    can finish with Root exit {
        self.sccs = sorted(self.sccs, key=_scc_head);
        report self.sccs;
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has found: bool = False;
    has reports: list[bool] = [];

    can begin with Root entry {
        visit [-->][?:Dep];
    }

    can probe with Dep entry {
        if self.found {
            skip;
        }
        if here.dep_id in self.active and self.active[here.dep_id] {
            self.found = True;
            skip;
        }
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.active[here.dep_id] = True;
        visit [-->][?:Dep] else {
            self.active[here.dep_id] = False;
            disengage;
        };
    }

    can unwind with Dep exit {
        self.active[here.dep_id] = False;
    }

    can finish with Root exit {
        report self.found;
    }
}

walker CondensationWalker {
    has sccs: list[list[str]];
    has rep_of: dict[str, str] = {};
    has adj: dict[str, dict[str, bool]] = {};
    has indeg: dict[str, int] = {};
    has queue: list[str] = [];
    has order: list[str] = [];
    has reports: list[list[str]] = [];

    can prep with Root entry {
        for comp in self.sccs {
            r = comp[0];
            self.adj[r] = {};
            self.indeg[r] = 0;
            for n in comp {
                self.rep_of[n] = r;
            }
        }
        visit [-->][?:Dep];
    }

    can scan with Dep entry {
        rs = self.rep_of.get(here.dep_id, here.dep_id);
        for tgt in [-->][?:Dep] {
            rd = self.rep_of.get(tgt.dep_id, tgt.dep_id);
            if rs != rd and rd not in self.adj[rs] {
                self.adj[rs][rd] = True;
                self.indeg[rd] = self.indeg.get(rd, 0) + 1;
            }
        }
        visit [-->];
    }

    can sort with Root exit {
        for r in sorted(self.indeg.keys()) {
            if self.indeg[r] == 0 {
                self.queue.append(r);
            }
        }
        while self.queue {
            self.queue.sort();
            cur = self.queue.pop(0);
            self.order.append(cur);
            for nxt in sorted(self.adj.get(cur, {}).keys()) {
                self.indeg[nxt] -= 1;
                if self.indeg[nxt] == 0 {
                    self.queue.append(nxt);
                }
            }
        }
        report self.order;
    }
}

def _find_dep(target: str) -> Dep | None {
    result = root spawn FindDep(target=target);
    if result.reports {
        return result.reports[0];
    }
    return None;
}

def _walker_list(result: object) -> list[str] {
    if result.reports and len(result.reports) > 0 {
        return result.reports[0];
    }
    return [];
}

def _norm_sccs(sccs: list[list[str]]) -> list[list[str]] {
    return sorted([sorted(c) for c in sccs]);
}

def canonical_id(store: LineageStore, node_id: str) -> str {
    cur = node_id;
    seen: dict[str, bool] = {};
    while cur in store.alias_map {
        if cur in seen {
            return cur;
        }
        seen[cur] = True;
        cur = store.alias_map[cur];
    }
    return cur;
}

def build_lineage(
    edges: list[tuple[str, str]],
    aliases: dict[str, str] | None = None,
) -> LineageStore {
    store = LineageStore(stamp=1);
    if aliases is not None {
        for (k, v) in aliases.items() {
            store.alias_map[k] = v;
        }
    }
    id_map: dict[str, Dep] = {};
    for (src, dst) in edges {
        cs = canonical_id(store, src);
        cd = canonical_id(store, dst);
        if cs not in id_map {
            n = Dep(dep_id=cs);
            root ++> n;
            id_map[cs] = n;
        }
        if cd not in id_map {
            n = Dep(dep_id=cd);
            root ++> n;
            id_map[cd] = n;
        }
    }
    for (src, dst) in edges {
        cs = canonical_id(store, src);
        cd = canonical_id(store, dst);
        a = id_map[cs];
        b = id_map[cd];
        a +>:Depends:+> b;
    }
    return store;
}

def materialize_sccs(store: LineageStore) -> list[list[str]] {
    if store.scc_cache is not None {
        return store.scc_cache;
    }
    result = root spawn MaterializeSccs();
    if result.reports and len(result.reports) > 0 {
        store.scc_cache = result.reports[0];
        return store.scc_cache;
    }
    store.scc_cache = [];
    return store.scc_cache;
}

def condensation_topo(store: LineageStore) -> list[str] {
    sccs = materialize_sccs(store);
    result = root spawn CondensationWalker(sccs=sccs);
    return _walker_list(result);
}

def has_cycle(store: LineageStore) -> bool {
    for comp in materialize_sccs(store) {
        if len(comp) > 1 {
            return True;
        }
    }
    for n in [-->][?:Dep] {
        for tgt in [n -->][?:Dep] {
            if tgt.dep_id == n.dep_id {
                return True;
            }
        }
    }
    result = root spawn CycleProbe();
    if result.reports {
        return result.reports[0];
    }
    return False;
}

def terminates(store: LineageStore) -> bool {
    return not has_cycle(store);
}

def reachable_from(store: LineageStore, start: str) -> list[str] {
    if store.stamp < 0 {
        return [];
    }
    start_dep = _find_dep(canonical_id(store, start));
    if start_dep is None {
        return [];
    }
    result = start_dep spawn ForwardReach();
    got = _walker_list(result);
    return sorted(got);
}

test "canonical identity resolves aliases" {
    store = build_lineage([], {"x": "a", "y": "a"});
    assert canonical_id(store, "x") == "a";
    assert canonical_id(store, "missing") == "missing";
}

test "materialize sccs once and terminate flags" {
    store = build_lineage(
        [
            ("a", "b"),
            ("b", "c"),
            ("c", "a"),
            ("a", "d"),
            ("d", "e"),
            ("f", "g"),
            ("g", "f"),
        ],
        {"x": "a", "z": "f"},
    );
    sccs = _norm_sccs(materialize_sccs(store));
    assert sccs == [["a", "b", "c"], ["d"], ["e"], ["f", "g"]];
    sccs2 = _norm_sccs(materialize_sccs(store));
    assert sccs2 == sccs;
    assert condensation_topo(store) == ["a", "d", "e", "f"];
    assert has_cycle(store) is True;
    assert terminates(store) is False;
}

test "reachable forward closure sorted" {
    store = build_lineage(
        [
            ("a", "b"),
            ("b", "c"),
            ("c", "a"),
            ("a", "d"),
            ("d", "e"),
            ("f", "g"),
            ("g", "f"),
        ],
        {"x": "a"},
    );
    assert reachable_from(store, "a") == ["a", "b", "c", "d", "e"];
    assert reachable_from(store, "f") == ["f", "g"];
    assert reachable_from(store, "missing") == [];
}

test "diamond adversarial revisit ordering" {
    store = build_lineage(
        [("p", "q"), ("p", "r"), ("q", "t"), ("r", "t"), ("t", "u")],
    );
    assert reachable_from(store, "p") == ["p", "q", "r", "t", "u"];
    assert terminates(store) is True;
    assert has_cycle(store) is False;
    assert _norm_sccs(materialize_sccs(store)) == [
        ["p"],
        ["q"],
        ["r"],
        ["t"],
        ["u"],
    ];
    assert condensation_topo(store) == ["p", "q", "r", "t", "u"];
}

test "acyclic dag terminates" {
    store = build_lineage([("m", "n"), ("n", "o")]);
    assert terminates(store) is True;
    assert condensation_topo(store) == ["m", "n", "o"];
}
