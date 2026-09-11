"""grandchallenge/QUANTUM-TECHNOLOGIES#114 — decoder pipeline stage ordering."""

class CycleError(Exception) {}

node Stage {
    has name: str;
}

edge Requires {}

obj DecoderPipeline {
    has stages: dict[str, Stage] = {};
}

walker DownstreamReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Stage entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<-:Requires:<-][?:Stage];
    }
}

def load_decoder_dag(
    stage_names: list[str],
    require_edges: list[tuple[str, str]],
) -> DecoderPipeline {
    pipe = DecoderPipeline();
    for stage in stage_names {
        nd = Stage(name=stage);
        root ++> nd;
        pipe.stages[stage] = nd;
    }
    for (upstream, downstream) in require_edges {
        u = pipe.stages.get(upstream, None);
        d = pipe.stages.get(downstream, None);
        if u is not None and d is not None { d +>:Requires:+> u; }
    }
    return pipe;
}

def execution_order(pipe: DecoderPipeline) -> list[str] {
    indegree: dict[str, int] = {};
    rev: dict[str, list[str]] = {};
    for sid in pipe.stages {
        indegree[sid] = 0;
        rev[sid] = [];
    }
    for sid in pipe.stages {
        nd = pipe.stages[sid];
        for up in [nd ->:Requires:->][?:Stage] {
            indegree[sid] += 1;
            rev[up.name].append(sid);
        }
    }
    order: list[str] = [];
    visited: dict[str, bool] = {};
    ready: dict[str, bool] = {};
    for sid in pipe.stages {
        if indegree[sid] == 0 { ready[sid] = True; }
    }
    while len(ready) > 0 {
        keys = sorted([s for s in ready.keys()]);
        stage_id = keys[0];
        next_ready: dict[str, bool] = {};
        for k in keys[1:] { next_ready[k] = True; }
        ready = next_ready;
        if stage_id in visited { continue; }
        visited[stage_id] = True;
        order.append(stage_id);
        for other in rev.get(stage_id, []) {
            indegree[other] -= 1;
            if indegree[other] == 0 and not (other in visited) {
                ready[other] = True;
            }
        }
    }
    if len(visited) != len(pipe.stages) {
        raise CycleError("stage dependency cycle");
    }
    return order;
}

def stage_reachable(pipe: DecoderPipeline, `root: str) -> list[str] {
    nd = pipe.stages.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DownstreamReach(claimed={}, reached=[]);
    out: list[str] = [];
    for s in w.reached {
        if s != `root { out.append(s); }
    }
    return sorted(out);
}

def compile_validate_decode_order(pipe: DecoderPipeline) -> list[str] {
    order = execution_order(pipe);
    phases = ["compile", "validate", "decode"];
    out: list[str] = [];
    for phase in phases {
        if phase in order { out.append(phase); }
    }
    for stage in order {
        dup = False;
        for x in out {
            if x == stage { dup = True; }
        }
        if not dup { out.append(stage); }
    }
    return out;
}
