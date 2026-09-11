"""SandeepVashishtha/Eventra#11396 — Optimize GitHub Actions with Dependency Caching.

Models GitHub Actions workflow jobs as a dependency DAG. Cache keys derive from
lockfile hashes; restore order and invalidation sweeps use typed job nodes,
DependsOn edges, and walkers with claim-map cycle policy.
"""

node Job {
    has name: str;
}

edge DependsOn {}

obj WorkflowCacheGraph {
    has lockfile_hash: dict[str, str] = {};
    has _ancestor_memo: dict[str, list[str]] = {};
    has jobs: dict[str, Job] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Job entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.found.append(here.name); }
        ups = [here ->:DependsOn:->][?:Job];
        names: list[str] = [];
        for u in ups { names.append(u.name); }
        for nm in sorted(names) {
            for u in ups {
                if u.name == nm and u.name not in self.claimed {
                    visit [u];
                }
            }
        }
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has touched: list[str] = [];
    has seeds: dict[str, bool] = {};

    can step with Job entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if not (here.name in self.seeds) { self.touched.append(here.name); }
        downs = [here <-:DependsOn:<-][?:Job];
        names: list[str] = [];
        for d in downs { names.append(d.name); }
        for nm in sorted(names) {
            for d in downs {
                if d.name == nm and d.name not in self.claimed {
                    visit [d];
                }
            }
        }
    }
}

def load_workflow_cache_graph(
    jobs: list[tuple[str, str]],
    depends: list[tuple[str, str]],
) -> WorkflowCacheGraph {
    g = WorkflowCacheGraph();
    for (name, lf_hash) in jobs {
        g.lockfile_hash[name] = lf_hash;
        if name not in g.jobs {
            nd = Job(name=name);
            root ++> nd;
            g.jobs[name] = nd;
        }
    }
    for (job, upstream) in depends {
        if job in g.jobs and upstream in g.lockfile_hash {
            jn = g.jobs.get(job, None);
            up = g.jobs.get(upstream, None);
            if jn is not None and up is not None {
                ups = [jn ->:DependsOn:-> up];
                if len(ups) == 0 { jn +>:DependsOn:+> up; }
            }
        }
    }
    return g;
}

def cache_key(g: WorkflowCacheGraph, job: str) -> str {
    if job not in g.lockfile_hash { return ""; }
    return f"{job}::{g.lockfile_hash[job]}";
}

def memo_ancestors(g: WorkflowCacheGraph, job: str) -> list[str] {
    if job not in g.lockfile_hash { return []; }
    if job in g._ancestor_memo { return g._ancestor_memo[job]; }
    nd = g.jobs.get(job, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, found=[], origin=job);
    out: list[str] = [];
    for nm in w.found {
        if nm != job { out.append(nm); }
    }
    out = sorted(out);
    g._ancestor_memo[job] = out;
    return out;
}

def restore_order(g: WorkflowCacheGraph, job: str) -> list[str] {
    anc = memo_ancestors(g, job);
    if not anc { return []; }
    anc_set: dict[str, bool] = {};
    for a in anc { anc_set[a] = True; }
    indeg: dict[str, int] = {};
    for a in anc { indeg[a] = 0; }
    for a in anc {
        nd = g.jobs.get(a, None);
        if nd is None { continue; }
        for up in [nd ->:DependsOn:->][?:Job] {
            if up.name in anc_set { indeg[a] += 1; }
        }
    }
    ready: list[str] = [];
    for a in anc {
        if indeg[a] == 0 { ready.append(a); }
    }
    ready = sorted(ready);
    order: list[str] = [];
    while len(ready) > 0 {
        u = ready[0];
        ready = ready[1:];
        order.append(u);
        nd = g.jobs.get(u, None);
        if nd is None { continue; }
        nxt: list[str] = [];
        for child in [nd <-:DependsOn:<-][?:Job] {
            if child.name in anc_set {
                indeg[child.name] -= 1;
                if indeg[child.name] == 0 { nxt.append(child.name); }
            }
        }
        for nm in sorted(nxt) { ready.append(nm); }
    }
    return order;
}

def downstream_jobs(g: WorkflowCacheGraph, changed_jobs: list[str]) -> list[str] {
    if not changed_jobs { return []; }
    seeds: dict[str, bool] = {};
    for j in changed_jobs {
        if j in g.lockfile_hash { seeds[j] = True; }
    }
    if not seeds { return []; }
    claimed: dict[str, bool] = {};
    touched: list[str] = [];
    seed_keys: list[str] = [];
    for j in seeds { seed_keys.append(j); }
    for j in sorted(seed_keys) {
        nd = g.jobs.get(j, None);
        if nd is not None {
            w = nd spawn DownstreamWalk(claimed=claimed, touched=touched, seeds=seeds);
            claimed = w.claimed;
            touched = w.touched;
        }
    }
    return sorted(touched);
}

def cache_keys_to_bust(g: WorkflowCacheGraph, changed_jobs: list[str]) -> list[str] {
    keys: list[str] = [];
    for j in changed_jobs {
        if j in g.lockfile_hash {
            k = cache_key(g, j);
            if k { keys.append(k); }
        }
    }
    for j in downstream_jobs(g, changed_jobs) {
        k = cache_key(g, j);
        if k { keys.append(k); }
    }
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for k in sorted(keys) {
        if k not in seen {
            seen[k] = True;
            out.append(k);
        }
    }
    return out;
}
