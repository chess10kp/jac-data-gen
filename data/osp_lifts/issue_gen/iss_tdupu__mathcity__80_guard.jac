"""tdupu/mathcity#80 — stale inactive workflow issue root candidates (reaper CTE)."""

node WorkflowUnit {
    has wid: str;
}

edge WispDep {
    has kind: str;
}

obj WorkflowStore {
    has _status: dict[str, str] = {};
    has _tier: dict[str, str] = {};
    has units: dict[str, WorkflowUnit] = {};
}

walker AscentWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with WorkflowUnit entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        if here.wid != self.origin { self.hits.append(here.wid); }
        nbrs = [here ->:WispDep:->][?:WorkflowUnit];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.wid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.wid == nm { visit [n]; }
            }
        }
    }
}

walker RootCandWalk {
    has claimed: dict[str, bool] = {};
    has issues: dict[str, bool] = {};
    has tier_map: dict[str, str] = {};

    can step with WorkflowUnit entry {
        if self.tier_map.get(here.wid, "issue") == "issue" {
            self.issues[here.wid] = True;
        }
        nbrs = [here ->:WispDep:->][?:WorkflowUnit];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.wid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.wid == nm and not (n.wid in self.claimed) {
                    self.claimed[n.wid] = True;
                    visit [n];
                }
            }
        }
    }
}

walker ReaperCountWalk {
    has claimed: dict[str, bool] = {};
    has steps: int = 0;

    can step with WorkflowUnit entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        self.steps += 1;
        nbrs = [here ->:WispDep:->][?:WorkflowUnit];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.wid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.wid == nm and not (n.wid in self.claimed) {
                    visit [n];
                }
            }
        }
    }
}

def _dominated_issues(
    store: WorkflowStore,
    claimed: dict[str, bool],
    issues: dict[str, bool],
) -> dict[str, bool] {
    dominated: dict[str, bool] = {};
    for src_id in claimed {
        if store._tier.get(src_id, "issue") != "issue" { continue; }
        src_nd = store.units.get(src_id, None);
        if src_nd is None { continue; }
        for tgt in [src_nd ->:WispDep:->][?:WorkflowUnit] {
            for e in [edge src_nd ->:WispDep:-> tgt] {
                if e.kind == "parent-child" and issues.get(tgt.wid, False) {
                    dominated[src_id] = True;
                }
            }
        }
    }
    return dominated;
}

def load_workflow_store(
    statuses: dict[str, str],
    tiers: dict[str, str],
    edges: list[tuple[str, str, str]],
) -> WorkflowStore {
    store = WorkflowStore();
    store._status = dict(statuses);
    store._tier = dict(tiers);
    for wid in statuses {
        nd = WorkflowUnit(wid=wid);
        root ++> nd;
        store.units[wid] = nd;
    }
    for (src, dst, kind) in edges {
        if src in store._status and dst in store._status {
            a = store.units.get(src, None);
            b = store.units.get(dst, None);
            if a is not None and b is not None { a +>:WispDep(kind=kind):+> b; }
        }
    }
    return store;
}

def dependency_ascent(store: WorkflowStore, start_id: str) -> list[str] {
    if start_id not in store._status { return []; }
    nd = store.units.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn AscentWalk(claimed={}, hits=[], origin=start_id);
    return sorted(w.hits);
}

def workflow_issue_root_candidates(store: WorkflowStore, start_id: str) -> list[str] {
    if start_id not in store._status { return []; }
    nd = store.units.get(start_id, None);
    if nd is None { return []; }
    claimed: dict[str, bool] = {start_id: True};
    w = nd spawn RootCandWalk(claimed=claimed, issues={}, tier_map=store._tier);
    dominated = _dominated_issues(store, w.claimed, w.issues);
    out: list[str] = [];
    for iid in w.issues {
        if not dominated.get(iid, False) { out.append(iid); }
    }
    return sorted(out);
}

def stale_inactive_issue_ids(store: WorkflowStore) -> list[str] {
    out: list[str] = [];
    for (nid, st) in store._status.items() {
        if store._tier.get(nid, "issue") == "issue" and st == "inactive" {
            out.append(nid);
        }
    }
    return sorted(out);
}

def reaper_visit_count(store: WorkflowStore, start_id: str) -> int {
    if start_id not in store._status { return 0; }
    nd = store.units.get(start_id, None);
    if nd is None { return 0; }
    w = nd spawn ReaperCountWalk(claimed={}, steps=0);
    return w.steps;
}

test "diamond revisit reaper count without double visit" {
    store = load_workflow_store(
        {"s": "active", "a": "active", "b": "active", "j": "active"},
        {},
        [("s", "a", "depends"), ("s", "b", "depends"), ("a", "j", "depends"), ("b", "j", "depends")],
    );
    assert reaper_visit_count(store, "s") == 4;;
    assert dependency_ascent(store, "s") == ["a", "b", "j"];;
    assert workflow_issue_root_candidates(store, "s") == ["a", "b", "j", "s"];;
}

test "unknown id tolerance across workflow queries" {
    store = load_workflow_store(
        {"a": "active"},
        {},
        [("a", "ghost", "depends"), ("ghost", "a", "depends")],
    );
    assert dependency_ascent(store, "missing") == [];;
    assert workflow_issue_root_candidates(store, "missing") == [];;
    assert reaper_visit_count(store, "missing") == 0;;
    assert dependency_ascent(store, "a") == [];;
    assert workflow_issue_root_candidates(store, "a") == ["a"];;
    assert reaper_visit_count(store, "a") == 1;;
}

test "parent child dominance prunes dominated issue roots" {
    store = load_workflow_store(
        {"s": "active", "hub": "active", "ia": "active", "ib": "active"},
        {"hub": "wisp"},
        [
            ("s", "hub", "depends"),
            ("hub", "ia", "depends"),
            ("hub", "ib", "depends"),
            ("ia", "ib", "parent-child"),
        ],
    );
    res = workflow_issue_root_candidates(store, "s");
    assert "ib" in res;;
    assert dependency_ascent(store, "s") == ["hub", "ia", "ib"];;
}

test "parent child to non issue retains candidate" {
    store = load_workflow_store(
        {"s": "active", "ia": "active", "w": "active"},
        {"w": "wisp"},
        [("s", "ia", "depends"), ("ia", "w", "parent-child")],
    );
    res1 = workflow_issue_root_candidates(store, "s");
    assert "ia" in res1;;
    res2 = workflow_issue_root_candidates(store, "ia");
    assert "ia" in res2;;
}

test "cycle skip revisit without disengage" {
    store = load_workflow_store(
        {"a": "active", "b": "active", "c": "active"},
        {},
        [("a", "b", "depends"), ("b", "c", "depends"), ("c", "a", "depends")],
    );
    assert reaper_visit_count(store, "a") == 3;;
    assert dependency_ascent(store, "a") == ["b", "c"];;
    assert workflow_issue_root_candidates(store, "a") == ["a", "b", "c"];;
}

test "stale inactive tier status filter" {
    store = load_workflow_store(
        {"i1": "inactive", "i2": "active", "w1": "inactive", "i3": "inactive"},
        {"w1": "wisp", "i3": "task"},
        [],
    );
    assert stale_inactive_issue_ids(store) == ["i1"];;
}
