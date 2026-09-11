"""k-nuth/kth#624 — CI workflow DAG downstream closure and cache diagnosis."""

glob PLATFORM_MACOS = "macos";
glob CACHE_RESTORED = "restored";
glob CACHE_MISSED = "missed";

node BuildJob {
    has job_id: str;
    has platform: str;
    has compile_secs: int;
    has test_secs: int;
    has ccache_hit_rate: float;
    has cache_state: str;
}

edge JobDepends {}

obj WorkflowStore {
    has jobs: dict[str, BuildJob] = {};
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can step with BuildJob entry {
        if here.job_id in self.claimed { skip; }
        self.claimed[here.job_id] = True;
        self.ids.append(here.job_id);
        kids = _sorted_downstream(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_downstream(nd: BuildJob) -> list[BuildJob] {
    kids: list[BuildJob] = [nd ->:JobDepends:->][?:BuildJob];
    names: list[str] = [];
    for ch in kids { names.append(ch.job_id); }
    names = sorted(names);
    out: list[BuildJob] = [];
    for nm in names { for ch in kids { if ch.job_id == nm { out.append(ch); } } }
    return out;
}

def _downstream_ids(store: WorkflowStore, start_id: str) -> list[str] {
    nd = store.jobs.get(start_id, None);
    if nd is None { return []; }
    w = nd spawn DownstreamWalk(claimed={}, ids=[]);
    return w.ids;
}

def fresh_workflow_store() -> WorkflowStore {
    return WorkflowStore();
}

def register_job(
    job_id: str,
    platform: str,
    compile_secs: int,
    test_secs: int,
    ccache_hit_rate: float,
    cache_state: str,
    store: WorkflowStore | None = None,
) -> WorkflowStore {
    s = store;
    if s is None { s = fresh_workflow_store(); }
    if job_id in s.jobs { raise ValueError("duplicate job id"); }
    nd = BuildJob(job_id=job_id, platform=platform, compile_secs=compile_secs, test_secs=test_secs, ccache_hit_rate=ccache_hit_rate, cache_state=cache_state);
    root ++> nd;
    s.jobs[job_id] = nd;
    return s;
}

def add_job_dependency(upstream_id: str, downstream_id: str, store: WorkflowStore) {
    if upstream_id not in store.jobs or downstream_id not in store.jobs { raise KeyError("unknown job id"); }
    if upstream_id == downstream_id { raise ValueError("self dependency"); }
    for jid in _downstream_ids(store, downstream_id) {
        if jid == upstream_id { raise ValueError("cycle"); }
    }
    up = store.jobs[upstream_id];
    down = store.jobs[downstream_id];
    seen = False;
    for ex in [up ->:JobDepends:->][?:BuildJob] { if ex.job_id == downstream_id { seen = True; } }
    if not seen { up +>:JobDepends:+> down; }
}

def direct_downstream_jobs(job_id: str, store: WorkflowStore) -> list[str] {
    if job_id not in store.jobs { raise KeyError(job_id); }
    out: list[str] = [];
    for ch in _sorted_downstream(store.jobs[job_id]) { out.append(ch.job_id); }
    return out;
}

def downstream_closure(job_id: str, store: WorkflowStore) -> list[str] {
    if job_id not in store.jobs { raise KeyError(job_id); }
    reach: list[str] = [];
    for jid in _downstream_ids(store, job_id) {
        if jid != job_id { reach.append(jid); }
    }
    return sorted(reach);
}

def workflow_build_order(store: WorkflowStore) -> list[str] | None {
    indeg: dict[str, int] = {};
    for jid in store.jobs { indeg[jid] = len([store.jobs[jid] <-:JobDepends:<-]); }
    order: list[str] = [];
    total = len(indeg);
    while len(order) < total {
        picked: list[str] = [];
        for jid in sorted(indeg.keys()) {
            if indeg[jid] == 0 { picked.append(jid); }
        }
        if len(picked) == 0 { return None; }
        for nid in picked {
            order.append(nid);
            nd = store.jobs[nid];
            for succ in [nd ->:JobDepends:->][?:BuildJob] { indeg[succ.job_id] = indeg[succ.job_id] - 1; }
            indeg[nid] = -1;
        }
    }
    return order;
}

def invalidate_downstream_on_rerun(root_job_id: str, store: WorkflowStore) -> list[str] {
    if root_job_id not in store.jobs { raise KeyError(root_job_id); }
    return sorted(_downstream_ids(store, root_job_id));
}

def cache_diagnosis(job_id: str, store: WorkflowStore) -> str {
    if job_id not in store.jobs { return "reject_unknown"; }
    nd = store.jobs[job_id];
    if nd.cache_state == CACHE_MISSED or nd.ccache_hit_rate < 0.5 { return "cache_miss"; }
    return "healthy";
}

def timing_variance_ratio(slow_compile_secs: int, normal_compile_secs: int) -> float {
    if normal_compile_secs <= 0 { return 0.0; }
    return slow_compile_secs / normal_compile_secs;
}

test "diamond downstream closure once only" {
    s = fresh_workflow_store();
    register_job("build", PLATFORM_MACOS, 1774, 120, 0.9, CACHE_RESTORED, s);
    register_job("lint", "linux", 90, 30, 0.8, CACHE_RESTORED, s);
    register_job("test_mac", PLATFORM_MACOS, 60, 300, 0.7, CACHE_RESTORED, s);
    register_job("test_lin", "linux", 55, 280, 0.6, CACHE_RESTORED, s);
    add_job_dependency("build", "lint", s);
    add_job_dependency("build", "test_mac", s);
    add_job_dependency("lint", "test_lin", s);
    add_job_dependency("test_mac", "test_lin", s);
    assert sorted(downstream_closure("build", s)) == ["lint", "test_lin", "test_mac"];
}

test "unknown job tolerance" {
    s = fresh_workflow_store();
    register_job("build", PLATFORM_MACOS, 400, 100, 0.9, CACHE_RESTORED, s);
    assert cache_diagnosis("ghost", s) == "reject_unknown";
    caught = False;
    try { downstream_closure("ghost", s); } except KeyError { caught = True; }
    assert caught;
}

test "workflow build order deterministic" {
    s = fresh_workflow_store();
    register_job("compile", "linux", 600, 0, 0.5, CACHE_MISSED, s);
    register_job("link", "linux", 120, 0, 0.6, CACHE_RESTORED, s);
    register_job("test", "linux", 0, 400, 0.0, CACHE_RESTORED, s);
    add_job_dependency("compile", "link", s);
    add_job_dependency("link", "test", s);
    assert workflow_build_order(s) == ["compile", "link", "test"];
}

test "invalidate downstream on rerun root set" {
    s = fresh_workflow_store();
    register_job("build", PLATFORM_MACOS, 1774, 120, 0.2, CACHE_MISSED, s);
    register_job("test", PLATFORM_MACOS, 0, 300, 0.1, CACHE_MISSED, s);
    add_job_dependency("build", "test", s);
    assert invalidate_downstream_on_rerun("build", s) == ["build", "test"];
    assert timing_variance_ratio(1774, 414) > 4.0;
}

test "cache diagnosis flags miss" {
    s = fresh_workflow_store();
    register_job("slow", PLATFORM_MACOS, 3125, 200, 0.1, CACHE_MISSED, s);
    register_job("fast", PLATFORM_MACOS, 414, 80, 0.95, CACHE_RESTORED, s);
    assert cache_diagnosis("slow", s) == "cache_miss";
    assert cache_diagnosis("fast", s) == "healthy";
}
