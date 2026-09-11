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
