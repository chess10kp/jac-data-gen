"""Guard: sethdford/shipwright#725."""

node Pipeline {
    has pid: str;
    has cached: str | None = None;
}

edge DependsOn {}
edge MemoOf {}

obj PipelineCache {
    has pipelines: dict[str, Pipeline] = {};

    def resolve(pid: str) -> Pipeline | None {
        return self.pipelines.get(pid, None);
    }
}

def build_cache(
    pipelines: list[str],
    depends: list[tuple[str, str]],
    memo_of: list[tuple[str, str]] | None = None,
) -> PipelineCache {
    g = PipelineCache(pipelines={});
    for pid in pipelines {
        nd = Pipeline(pid=pid);
        root ++> nd;
        g.pipelines[pid] = nd;
    }
    for (upstream, downstream) in depends {
        u = g.pipelines.get(upstream, None);
        d = g.pipelines.get(downstream, None);
        if u is not None and d is not None {
            u +>:DependsOn:+> d;
        }
    }
    for (child, parent) in memo_of or [] {
        ch = g.pipelines.get(child, None);
        pa = g.pipelines.get(parent, None);
        if ch is not None and pa is not None {
            ch +>:MemoOf:+> pa;
        }
    }
    return g;
}

def store_result(g: PipelineCache, pipeline_id: str, payload: str) -> bool {
    nd = g.resolve(pipeline_id);
    if nd is None {
        return False;
    }
    nd.cached = payload;
    return True;
}

def read_result(g: PipelineCache, pipeline_id: str) -> str | None {
    nd = g.resolve(pipeline_id);
    if nd is None {
        return None;
    }
    return nd.cached;
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has origin: str = "";

    can step with Pipeline entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        if here.pid != self.origin {
            self.out.append(here.pid);
        }
        visit [->:DependsOn:->] else { disengage; };
    }
}

def downstream_pipelines(g: PipelineCache, pipeline_id: str) -> list[str] {
    nd = g.resolve(pipeline_id);
    if nd is None {
        return [];
    }
    w = nd spawn DownstreamWalk(claimed={}, out=[], origin=pipeline_id);
    return sorted(w.out);
}

def _memo_ancestor_pids(g: PipelineCache, pipeline_id: str) -> list[str] {
    out: list[str] = [];
    seen: set[str] = set();
    nd = g.resolve(pipeline_id);
    if nd is None {
        return [];
    }
    parents = [nd <-:MemoOf:<-][?:Pipeline];
    while parents {
        p = parents[0];
        if p.pid in seen {
            break;
        }
        seen.add(p.pid);
        out.append(p.pid);
        parents = [p <-:MemoOf:<-][?:Pipeline];
    }
    return sorted(out);
}

def invalidate_on_change(g: PipelineCache, pipeline_id: str) -> list[str] {
    nd = g.resolve(pipeline_id);
    if nd is None {
        return [];
    }
    w = nd spawn DownstreamWalk(claimed={}, out=[], origin=pipeline_id);
    target_ids = sorted(set([pipeline_id] + w.out + _memo_ancestor_pids(g, pipeline_id)));
    cleared: list[str] = [];
    for pid in target_ids {
        p = g.resolve(pid);
        if p is not None and p.cached is not None {
            p.cached = None;
            cleared.append(pid);
        }
    }
    return cleared;
}

test "cache store read and invalidate" {
    c = build_cache(
        ["fetch", "build", "test", "deploy"],
        [("fetch", "build"), ("build", "test"), ("test", "deploy")],
        [("deploy", "fetch")],
    );
    assert store_result(c, "build", "artifact:v1") == True;
    assert read_result(c, "build") == "artifact:v1";
    assert store_result(c, "deploy", "bundle:v1") == True;
    assert downstream_pipelines(c, "build") == ["deploy", "test"];
    assert invalidate_on_change(c, "build") == ["build", "deploy", "fetch", "test"];
    assert read_result(c, "test") is None;
    assert read_result(c, "deploy") is None;
}

test "diamond adversarial downstream revisit" {
    g = build_cache(
        ["hub", "left", "right", "sink"],
        [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
    );
    assert downstream_pipelines(g, "hub") == ["left", "right", "sink"];
    assert store_result(g, "sink", "cached") == True;
    assert invalidate_on_change(g, "hub") == ["left", "right", "sink"];
}

test "cycle downstream terminates" {
    g = build_cache(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert downstream_pipelines(g, "a") == ["b", "c"];
    assert len(downstream_pipelines(g, "a")) == 2;
}

test "unknown pipeline tolerant" {
    g = build_cache(["x"], []);
    assert store_result(g, "ghost", "v") == False;
    assert read_result(g, "ghost") is None;
    assert downstream_pipelines(g, "ghost") == [];
    assert invalidate_on_change(g, "ghost") == [];
}
