"""embabel/dice#67 — Extraction run lineage with parent/superseded chains."""

node Run {
    has rid: str;
    has tenant: str;
    has status: str = "completed";
}

edge ParentRun {}
edge SupersededBy {}

obj RunStore {
    has runs: dict[str, Run] = {};
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has edge_kind: str = "parent";
    has max_depth: int = 10;
    has depth: int = 0;

    can step with Run entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        if self.depth > 0 { self.hits.append(here.rid); }
        if self.depth >= self.max_depth { disengage; }
        self.depth += 1;
        if self.edge_kind == "parent" {
            visit [<-:ParentRun:<-][?:Run];
        } else {
            visit [->:SupersededBy:->][?:Run];
        }
    }
}

def load_runs(
    runs: list[tuple[str, str]],
    parents: list[tuple[str, str]],
    superseded: list[tuple[str, str]],
    statuses: list[tuple[str, str]],
) -> RunStore {
    store = RunStore();
    for (rid, tenant) in runs {
        if rid not in store.runs {
            nd = Run(rid=rid, tenant=tenant);
            root ++> nd;
            store.runs[rid] = nd;
        }
    }
    for (child, parent) in parents {
        c = store.runs.get(child, None);
        p = store.runs.get(parent, None);
        if c is not None and p is not None { p +>:ParentRun:+> c; }
    }
    for (old, new) in superseded {
        o = store.runs.get(old, None);
        n = store.runs.get(new, None);
        if o is not None and n is not None { o +>:SupersededBy:+> n; }
    }
    for (rid, status) in statuses {
        r = store.runs.get(rid, None);
        if r is not None { r.status = status; }
    }
    return store;
}

def parent_lineage(store: RunStore, run_id: str, max_depth: int = 10) -> list[str] {
    nd = store.runs.get(run_id, None);
    if nd is None { return []; }
    w = nd spawn LineageWalk(
        claimed={}, hits=[], edge_kind="parent", max_depth=max_depth, depth=0
    );
    return sorted(w.hits);
}

def superseded_chain(store: RunStore, run_id: str, max_depth: int = 10) -> list[str] {
    nd = store.runs.get(run_id, None);
    if nd is None { return []; }
    w = nd spawn LineageWalk(
        claimed={}, hits=[], edge_kind="superseded", max_depth=max_depth, depth=0
    );
    return sorted(w.hits);
}

def would_create_parent_cycle(store: RunStore, child: str, new_parent: str) -> bool {
    if child not in store.runs or new_parent not in store.runs { return False; }
    if child == new_parent { return True; }
    seen: dict[str, bool] = {child: True};
    cur: Run | None = store.runs.get(new_parent, None);
    while cur is not None {
        if cur.rid in seen { return True; }
        seen[cur.rid] = True;
        parents = [cur <-:ParentRun:<-][?:Run];
        if len(parents) == 0 { break; }
        cur = parents[0];
    }
    return False;
}

def set_parent(store: RunStore, child: str, parent: str | None) -> None {
    if child not in store.runs { raise KeyError(child); }
    if parent is not None {
        if parent not in store.runs { raise KeyError(parent); }
        if would_create_parent_cycle(store, child, parent) {
            raise ValueError("parent cycle");
        }
    }
    c = store.runs[child];
    old = [c <-:ParentRun:<-][?:Run];
    for op in old { op del ->:ParentRun:-> c; }
    if parent is not None {
        store.runs[parent] +>:ParentRun:+> c;
    }
}

def runs_for_tenant(store: RunStore, tenant: str) -> list[str] {
    out: list[str] = [];
    for (rid, r) in store.runs.items() {
        if r.tenant == tenant { out.append(rid); }
    }
    return sorted(out);
}

def run_status(store: RunStore, run_id: str) -> str | None {
    r = store.runs.get(run_id, None);
    if r is None { return None; }
    return r.status;
}
