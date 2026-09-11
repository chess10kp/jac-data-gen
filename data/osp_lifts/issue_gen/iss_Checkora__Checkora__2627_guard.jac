"""Checkora/Checkora#2627 — CI: Add dependency caching to reduce workflow execution time."""

node Job {
    has name: str;
}

edge DependsOn {}

obj CiCacheGraph {
    has lockfile_hash: dict[str, str] = {};
    has deps: dict[str, list[str]] = {};
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
        if not self.seeds.get(here.name, False) { self.touched.append(here.name); }
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

walker AncReadyWalk {
    has anc_set: dict[str, bool] = {};
    has done: dict[str, bool] = {};
    has target: str = "";
    has ready: bool = False;

    can step with Job entry {
        if here.name != self.target { skip; }
        if not self.anc_set.get(here.name, False) { skip; }
        if here.name in self.done { skip; }
        ups = [here ->:DependsOn:->][?:Job];
        for up in ups {
            if self.anc_set.get(up.name, False) and not self.done.get(up.name, False) {
                skip;
            }
        }
        self.ready = True;
    }
}

def load_ci_cache_graph(
    jobs: list[tuple[str, str]],
    depends: list[tuple[str, str]],
) -> CiCacheGraph {
    g = CiCacheGraph();
    for (name, lf_hash) in jobs {
        g.lockfile_hash[name] = lf_hash;
        g.deps.setdefault(name, []);
        if name not in g.jobs {
            nd = Job(name=name);
            root ++> nd;
            g.jobs[name] = nd;
        }
    }
    for (job, upstream) in depends {
        if job in g.deps and upstream in g.lockfile_hash {
            if upstream not in g.deps[job] {
                g.deps[job].append(upstream);
                jn = g.jobs.get(job, None);
                up = g.jobs.get(upstream, None);
                if jn is not None and up is not None {
                    jn +>:DependsOn:+> up;
                }
            }
        }
    }
    return g;
}

def cache_key(g: CiCacheGraph, job: str) -> str {
    if job not in g.lockfile_hash { return ""; }
    return f"{job}::{g.lockfile_hash[job]}";
}

def memo_ancestors(g: CiCacheGraph, job: str) -> list[str] {
    if job not in g.lockfile_hash { return []; }
    if job in g._ancestor_memo { return g._ancestor_memo[job]; }
    nd = g.jobs.get(job, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, found=[], origin=job);
    out = sorted(w.found);
    g._ancestor_memo[job] = out;
    return out;
}

def restore_order(g: CiCacheGraph, job: str) -> list[str] {
    anc = memo_ancestors(g, job);
    if not anc { return []; }
    anc_set: dict[str, bool] = {};
    for a in anc { anc_set[a] = True; }
    done: dict[str, bool] = {};
    order: list[str] = [];
    pending: list[str] = [];
    for nm in anc_set.keys() { pending.append(nm); }
    while len(done) < len(anc) {
        wave: list[str] = [];
        for nm in sorted(pending) {
            if nm in done { continue; }
            nd = g.jobs.get(nm, None);
            if nd is None { continue; }
            w = nd spawn AncReadyWalk(
                anc_set=anc_set, done=done, target=nm, ready=False
            );
            if w.ready { wave.append(nm); }
        }
        if not wave { break; }
        for nm in wave {
            done[nm] = True;
            order.append(nm);
        }
    }
    return order;
}

def downstream_jobs(g: CiCacheGraph, changed_jobs: list[str]) -> list[str] {
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

def cache_keys_to_bust(g: CiCacheGraph, changed_jobs: list[str]) -> list[str] {
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

test "cycle revisit ancestor closure" {
    g = load_ci_cache_graph(
        [("a", "ha"), ("b", "hb"), ("c", "hc")],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert memo_ancestors(g, "a") == ["b", "c"];
    assert restore_order(g, "a") == ["c", "b"];
}

test "downstream cycle fanout" {
    g = load_ci_cache_graph(
        [("a", "ha"), ("b", "hb"), ("c", "hc")],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert downstream_jobs(g, ["c"]) == ["a", "b"];
    assert cache_keys_to_bust(g, ["c"]) == ["a::ha", "b::hb", "c::hc"];
}

test "downstream diamond fanout" {
    g = load_ci_cache_graph(
        [("hub", "h1"), ("mid_a", "h2"), ("mid_b", "h3"), ("leaf", "h4")],
        [("leaf", "hub"), ("mid_a", "leaf"), ("mid_b", "leaf")],
    );
    assert downstream_jobs(g, ["hub"]) == ["leaf", "mid_a", "mid_b"];
}

test "unknown and empty tolerance" {
    g = load_ci_cache_graph([("only", "h1")], []);
    assert cache_key(g, "missing") == "";
    assert memo_ancestors(g, "missing") == [];
    assert restore_order(g, "missing") == [];
    assert downstream_jobs(g, []) == [];
    assert cache_keys_to_bust(g, ["ghost"]) == [];
}

test "ancestor memoization" {
    g = load_ci_cache_graph(
        [("x", "hx"), ("y", "hy")],
        [("x", "y")],
    );
    assert memo_ancestors(g, "x") == ["y"];
    assert memo_ancestors(g, "x") == ["y"];
    assert g._ancestor_memo["x"] == ["y"];
}

test "duplicate upstream edge ignored" {
    g = load_ci_cache_graph(
        [("a", "ha"), ("b", "hb")],
        [("a", "b"), ("a", "b")],
    );
    assert g.deps["a"] == ["b"];
    assert memo_ancestors(g, "a") == ["b"];
}

test "diamond ancestor revisit restore order" {
    g = load_ci_cache_graph(
        [("base", "h0"), ("left", "h1"), ("right", "h2"), ("join", "h3")],
        [("join", "left"), ("join", "right"), ("left", "base"), ("right", "base")],
    );
    assert memo_ancestors(g, "join") == ["base", "left", "right"];;
    assert restore_order(g, "join") == ["base", "left", "right"];;
}

test "ghost upstream not in lockfile" {
    g = load_ci_cache_graph(
        [("a", "ha"), ("b", "hb")],
        [("a", "ghost"), ("a", "b")],
    );
    assert g.deps["a"] == ["b"];;
    assert memo_ancestors(g, "a") == ["b"];;
    assert restore_order(g, "a") == ["b"];;
}

test "overlapping multi seed downstream dedupe" {
    g = load_ci_cache_graph(
        [("a", "ha"), ("b", "hb"), ("c", "hc"), ("d", "hd")],
        [("c", "a"), ("d", "a"), ("d", "b")],
    );
    assert downstream_jobs(g, ["a", "b"]) == ["c", "d"];;
    assert cache_keys_to_bust(g, ["a", "b"]) == ["a::ha", "b::hb", "c::hc", "d::hd"];;
}

test "unregistered job name in depends ignored" {
    g = load_ci_cache_graph(
        [("only", "h1")],
        [("phantom", "only"), ("only", "phantom")],
    );
    assert "phantom" not in g.deps;;
    assert g.deps["only"] == [];;
    assert memo_ancestors(g, "only") == [];;
}

test "mixed unknown seed cache bust partial" {
    g = load_ci_cache_graph(
        [("hub", "h1"), ("leaf", "h2")],
        [("leaf", "hub")],
    );
    assert downstream_jobs(g, ["ghost", "hub"]) == ["leaf"];;
    assert cache_keys_to_bust(g, ["ghost", "hub"]) == ["hub::h1", "leaf::h2"];;
}

test "empty lockfile hash still keys" {
    g = load_ci_cache_graph([("bare", "")], []);
    assert cache_key(g, "bare") == "bare::";;
    assert cache_keys_to_bust(g, ["bare"]) == ["bare::"];;
}
