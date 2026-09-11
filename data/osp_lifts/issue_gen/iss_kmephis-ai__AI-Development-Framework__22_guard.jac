"""kmephis-ai/AI-Development-Framework#22 — Foundation roadmap DAG and trace reach."""

glob STATUS_COMPLETED = "COMPLETED";
glob TRACE_REQUIREMENT = "requirement";
glob TRACE_DECISION = "decision";

node RoadmapTask {
    has task_id: str;
    has status: str;
}

node TraceEntity {
    has entity_id: str;
    has kind: str;
    has rel: str;
}

edge TaskDepends {}
edge TraceLink {}

obj FoundationStore {
    has tasks: dict[str, RoadmapTask] = {};
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can step with RoadmapTask entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.ids.append(here.task_id);
        kids = _sorted_downstream(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can step with RoadmapTask entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.ids.append(here.task_id);
        parents = _sorted_upstream(here);
        i = len(parents) - 1;
        while i >= 0 { visit :0: [parents[i]]; i -= 1; }
    }
}

def _sorted_downstream(nd: RoadmapTask) -> list[RoadmapTask] {
    kids: list[RoadmapTask] = [nd ->:TaskDepends:->][?:RoadmapTask];
    names: list[str] = [];
    for ch in kids { names.append(ch.task_id); }
    names = sorted(names);
    out: list[RoadmapTask] = [];
    for nm in names { for ch in kids { if ch.task_id == nm { out.append(ch); } } }
    return out;
}

def _sorted_upstream(nd: RoadmapTask) -> list[RoadmapTask] {
    parents: list[RoadmapTask] = [nd <-:TaskDepends:<-][?:RoadmapTask];
    names: list[str] = [];
    for p in parents { names.append(p.task_id); }
    names = sorted(names);
    out: list[RoadmapTask] = [];
    for nm in names { for p in parents { if p.task_id == nm { out.append(p); } } }
    return out;
}

def _downstream_ids(store: FoundationStore, start_id: str) -> list[str] {
    nd = store.tasks.get(start_id, None);
    if nd is None { return []; }
    dw = nd spawn DownstreamWalk(claimed={}, ids=[]);
    return dw.ids;
}

def _upstream_ids(store: FoundationStore, start_id: str) -> list[str] {
    nd = store.tasks.get(start_id, None);
    if nd is None { return []; }
    uw = nd spawn UpstreamWalk(claimed={}, ids=[]);
    return uw.ids;
}

def fresh_foundation_store -> FoundationStore {
    return FoundationStore();
}

def register_task(task_id: str, status: str, store: FoundationStore | None = None) -> FoundationStore {
    s = store;
    if s is None { s = fresh_foundation_store(); }
    if task_id in s.tasks { raise ValueError("duplicate task id"); }
    nd = RoadmapTask(task_id=task_id, status=status);
    root ++> nd;
    s.tasks[task_id] = nd;
    return s;
}

def add_task_dependency(upstream_id: str, downstream_id: str, store: FoundationStore) {
    if upstream_id not in store.tasks or downstream_id not in store.tasks { raise KeyError("unknown task id"); }
    if upstream_id == downstream_id { raise ValueError("self dependency"); }
    for jid in _downstream_ids(store, downstream_id) {
        if jid == upstream_id { raise ValueError("cycle"); }
    }
    up = store.tasks[upstream_id];
    down = store.tasks[downstream_id];
    seen = False;
    for ex in [up ->:TaskDepends:->][?:RoadmapTask] { if ex.task_id == downstream_id { seen = True; } }
    if not seen { up +>:TaskDepends:+> down; }
}

def add_trace_ref(task_id: str, entity_id: str, kind: str, rel: str, store: FoundationStore) {
    if task_id not in store.tasks { raise KeyError("unknown task id"); }
    ent = TraceEntity(entity_id=entity_id, kind=kind, rel=rel);
    root ++> ent;
    store.tasks[task_id] +>:TraceLink:+> ent;
}

def downstream_closure(task_id: str, store: FoundationStore) -> list[str] {
    if task_id not in store.tasks { raise KeyError(task_id); }
    reach: list[str] = [];
    for tid in _downstream_ids(store, task_id) {
        if tid != task_id { reach.append(tid); }
    }
    return sorted(reach);
}

def upstream_closure(task_id: str, store: FoundationStore) -> list[str] {
    if task_id not in store.tasks { raise KeyError(task_id); }
    reach: list[str] = [];
    for tid in _upstream_ids(store, task_id) {
        if tid != task_id { reach.append(tid); }
    }
    return sorted(reach);
}

def critical_path_order(store: FoundationStore) -> list[str] | None {
    indeg: dict[str, int] = {};
    for tid in store.tasks { indeg[tid] = len([store.tasks[tid] <-:TaskDepends:<-]); }
    order: list[str] = [];
    total = len(indeg);
    while len(order) < total {
        picked: list[str] = [];
        for tid in sorted(indeg.keys()) {
            if indeg[tid] == 0 { picked.append(tid); }
        }
        if len(picked) == 0 { return None; }
        for nid in picked {
            order.append(nid);
            nd = store.tasks[nid];
            for succ in [nd ->:TaskDepends:->][?:RoadmapTask] { indeg[succ.task_id] = indeg[succ.task_id] - 1; }
            indeg[nid] = -1;
        }
    }
    return order;
}

def trace_refs_for_task(task_id: str, store: FoundationStore) -> list[tuple[str, str, str]] {
    if task_id not in store.tasks { raise KeyError(task_id); }
    out: list[tuple[str, str, str]] = [];
    for ent in [store.tasks[task_id] ->:TraceLink:->][?:TraceEntity] {
        out.append((ent.entity_id, ent.kind, ent.rel));
    }
    return sorted(out);
}

def validate_foundation_dag(store: FoundationStore) -> list[tuple[str, str]] {
    if critical_path_order(store) is None { return [("cycle", "detected")]; }
    return [];
}

test "diamond downstream closure once only" {
    s = fresh_foundation_store();
    register_task("ROADMAP-001", STATUS_COMPLETED, s);
    register_task("AIWORK-001", STATUS_COMPLETED, s);
    register_task("TRACE-001", STATUS_COMPLETED, s);
    register_task("CONSUMER-001", "PENDING", s);
    add_task_dependency("ROADMAP-001", "AIWORK-001", s);
    add_task_dependency("ROADMAP-001", "TRACE-001", s);
    add_task_dependency("AIWORK-001", "CONSUMER-001", s);
    add_task_dependency("TRACE-001", "CONSUMER-001", s);
    assert sorted(downstream_closure("ROADMAP-001", s)) == ["AIWORK-001", "CONSUMER-001", "TRACE-001"];
}

test "unknown task tolerance" {
    s = fresh_foundation_store();
    register_task("FND-001", STATUS_COMPLETED, s);
    caught = False;
    try { downstream_closure("ghost", s); } except KeyError { caught = True; }
    assert caught;
    try { add_trace_ref("ghost", "req-1", TRACE_REQUIREMENT, "requires", s); } except KeyError { caught = True; }
    assert caught;
}

test "foundation critical path order" {
    s = fresh_foundation_store();
    register_task("FND-001", STATUS_COMPLETED, s);
    register_task("DEVENV-001", STATUS_COMPLETED, s);
    register_task("TRACE-001", STATUS_COMPLETED, s);
    add_task_dependency("FND-001", "DEVENV-001", s);
    add_task_dependency("DEVENV-001", "TRACE-001", s);
    assert critical_path_order(s) == ["FND-001", "DEVENV-001", "TRACE-001"];
    assert upstream_closure("TRACE-001", s) == ["DEVENV-001", "FND-001"];
    assert validate_foundation_dag(s) == [];
}

test "trace refs stored per task" {
    s = fresh_foundation_store();
    register_task("TRACE-001", STATUS_COMPLETED, s);
    add_trace_ref("TRACE-001", "req-42", TRACE_REQUIREMENT, "requires", s);
    add_trace_ref("TRACE-001", "dec-7", TRACE_DECISION, "records", s);
    assert trace_refs_for_task("TRACE-001", s) == [("dec-7", "decision", "records"), ("req-42", "requirement", "requires")];
}

test "cycle add rejected fail closed" {
    s = fresh_foundation_store();
    register_task("a", STATUS_COMPLETED, s);
    register_task("b", STATUS_COMPLETED, s);
    add_task_dependency("a", "b", s);
    caught = False;
    try { add_task_dependency("b", "a", s); } except ValueError { caught = True; }
    assert caught;
    assert validate_foundation_dag(s) == [];
}
