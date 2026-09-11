"""EffortlessMetrics/perl-lsp-swarm#11721 — stable stage contract (OSP lift)."""

obj PipelineStore {
    has stamp: int = 0;
}

node Stage {
    has sid: str;
    has owner: str;
}

edge HardDep {}

walker CycleProbe {
    has color: dict[str, int] = {};
    has found: bool = False;

    can step with Stage entry {
        if self.found { disengage; }
        c = self.color.get(here.sid, 0);
        if c == 1 { self.found = True; disengage; }
        if c == 2 { skip; }
        self.color[here.sid] = 1;
        visit [->:HardDep:->][?:Stage];
        self.color[here.sid] = 2;
    }
}

walker OwnerClosure {
    has claimed: dict[str, bool] = {};
    has owners: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for s in [-->][?:Stage] {
            if s.sid == self.start { visit [s]; }
        }
    }

    can step with Stage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.owners.append(here.owner);
        visit [->:HardDep:->][?:Stage] else { disengage; };
    }

    can finish with Root exit {
        report self.owners;
    }
}

def _wire(
    stages: list[tuple[str, str]],
    hard_deps: list[tuple[str, str]],
) {
    mp: dict[str, Stage] = {};
    for (sid, owner) in stages {
        if sid not in mp {
            n = Stage(sid=sid, owner=owner);
            root ++> n;
            mp[sid] = n;
        }
    }
    for (stage_id, dep_id) in hard_deps {
        st = mp.get(stage_id, None);
        dep = mp.get(dep_id, None);
        if st is not None and dep is not None { st +>:HardDep:+> dep; }
    }
}

def _stage(sid: str) -> Stage | None {
    for s in [-->][?:Stage] {
        if s.sid == sid { return s; }
    }
    return None;
}

def load_pipeline(
    stages: list[tuple[str, str]],
    hard_deps: list[tuple[str, str]],
) -> PipelineStore {
    _wire(stages, hard_deps);
    return PipelineStore(stamp=1);
}

def _has_cycle() -> bool {
    for stg in [-->][?:Stage] {
        w = stg spawn CycleProbe(color={}, found=False);
        if w.found { return True; }
    }
    return False;
}

def stage_order(g: PipelineStore) -> list[list[str]] | None {
    _ = g;
    if _has_cycle() { return None; }
    indeg: dict[str, int] = {};
    for stg in [-->][?:Stage] {
        indeg[stg.sid] = len([stg ->:HardDep:->][?:Stage]);
    }
    waves: list[list[str]] = [];
    ready = sorted([sid for (sid, d) in indeg.items() if d == 0]);
    while ready {
        waves.append(ready);
        nxt: list[str] = [];
        for nm in ready {
            cur = _stage(nm);
            if cur is None { continue; }
            for dep in [cur <-:HardDep:<-][?:Stage] {
                indeg[dep.sid] -= 1;
                if indeg[dep.sid] == 0 { nxt.append(dep.sid); }
            }
        }
        ready = sorted(nxt);
    }
    total = 0;
    for w in waves { total += len(w); }
    return waves if total == len(indeg) else None;
}

def owners_for(g: PipelineStore, stage: str) -> list[str] {
    _ = g;
    anchor = _stage(stage);
    if anchor is None { return []; }
    w = root spawn OwnerClosure(start=stage, claimed={}, owners=[]);
    raw = w.reports[0] if w.reports else [];
    uniq: dict[str, bool] = {};
    for o in raw { uniq[o] = True; }
    return sorted(uniq.keys());
}
