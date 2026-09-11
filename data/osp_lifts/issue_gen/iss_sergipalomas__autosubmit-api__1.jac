"""sergipalomas/autosubmit-api#1 — Experiment job dependency readiness graph."""

obj JobGraph {
    has jobs: dict[str, Job] = {};
}

node Job {
    has jid: str;
}

edge BlockedBy {}

def load_job_graph(
    jobs: list[str],
    block_edges: list[tuple[str, str]],
) -> JobGraph {
    g = JobGraph();
    for jid in jobs {
        if jid not in g.jobs {
            nd = Job(jid=jid);
            root ++> nd;
            g.jobs[jid] = nd;
        }
    }
    for (blocker, blocked) in block_edges {
        a = g.jobs.get(blocker, None);
        b = g.jobs.get(blocked, None);
        if a is not None and b is not None { a +>:BlockedBy:+> b; }
    }
    return g;
}

def critical_predecessors(g: JobGraph, job_id: str) -> list[str] {
    if job_id not in g.jobs { return []; }
    claimed: dict[str, bool] = {job_id: True};
    snap: list[str] = [job_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.jobs.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:BlockedBy:<-][?:Job] {
            if p.jid not in claimed {
                claimed[p.jid] = True;
                snap.append(p.jid);
            }
        }
    }
    ids: list[str] = [];
    for jid in claimed.keys() { ids.append(jid); }
    ids.sort();
    return ids;
}

def ready_jobs(g: JobGraph, finished: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for f in finished { done[f] = True; }
    ready: list[str] = [];
    for jid in g.jobs.keys() {
        if jid in done { continue; }
        needs = critical_predecessors(g, jid);
        ok = True;
        for p in needs {
            if p != jid and p not in done { ok = False; }
        }
        if ok { ready.append(jid); }
    }
    ready.sort();
    return ready;
}
