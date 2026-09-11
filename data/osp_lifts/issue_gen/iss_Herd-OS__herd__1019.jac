"""Herd-OS/herd#1019 — workflow dispatch dependency frontier."""

node Job {
    has jid: str;
    has status: str = "pending";
}

edge DependsOn {}

obj DispatchGraph {
    has jobs: dict[str, Job] = {};
}

def load_dispatch(
    jobs: list[str],
    depends_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> DispatchGraph {
    g = DispatchGraph();
    for jid in jobs {
        nd = Job(jid=jid);
        root ++> nd;
        g.jobs[jid] = nd;
    }
    for (blocker, blocked) in depends_edges {
        b = g.jobs.get(blocker, None);
        d = g.jobs.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    if status is not None {
        for (k, v) in status.items() {
            st_nd = g.jobs.get(k, None);
            if st_nd is not None { st_nd.status = v; }
        }
    }
    return g;
}

def _open_blockers(store: DispatchGraph, job: str) -> list[str] {
    nd = store.jobs.get(job, None);
    if nd is None { return []; }
    out: list[str] = [];
    for dep in [nd ->:DependsOn:->][?:Job] {
        if dep.status != "done" { out.append(dep.jid); }
    }
    return sorted(out);
}

def frontier_jobs(store: DispatchGraph) -> list[str] {
    out: list[str] = [];
    for jid in sorted(store.jobs.keys()) {
        nd = store.jobs.get(jid, None);
        if nd is None or nd.status != "pending" { continue; }
        if len(_open_blockers(store, jid)) == 0 { out.append(jid); }
    }
    return out;
}

def blocked_by(store: DispatchGraph, job: str) -> list[str] {
    if job not in store.jobs { return []; }
    return _open_blockers(store, job);
}

def dispatch_ready_count(store: DispatchGraph) -> int {
    return len(frontier_jobs(store));
}
