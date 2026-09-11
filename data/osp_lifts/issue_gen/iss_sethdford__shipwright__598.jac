node Stage { has sid: str; has name: str; has duration: int = 1; }
node Pipeline { has name: str = "main"; }
edge Blocks {}
edge Contains {}
walker CollectStages {
    has claimed: dict[str, bool] = {};
    has result: list[Stage] = [];
    can gather with Pipeline entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("gather pipeline");
        for st in [here ->:Contains:->][?:Stage] { visit [st]; }
    }
    can gather_stage with Stage entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.result.append(here);
        print(here.sid);
    }
}
def get_all_stages(pl: Pipeline) -> list[Stage] {
    w: CollectStages = pl spawn CollectStages(claimed={}, result=[]);
    return w.result;
}
def make_pipeline(name: str) -> Pipeline {
    pl: Pipeline = Pipeline(name=name);
    root ++> pl;
    return pl;
}
def find_stage(pl: Pipeline, sid: str) -> Stage | None {
    stages: list[Stage] = get_all_stages(pl);
    for st in stages { if st.sid == sid { return st; } }
    return None;
}
def add_stage(pl: Pipeline, sid: str, name: str, duration: int) -> Stage {
    existing = find_stage(pl, sid);
    if existing is not None { return existing; }
    st: Stage = Stage(sid=sid, name=name, duration=duration);
    pl +>:Contains:+> st;
    return st;
}
def add_dependency(pl: Pipeline, before: str, after: str) -> bool {
    src = find_stage(pl, before);
    if src is None { return False; }
    dst = find_stage(pl, after);
    if dst is None { return False; }
    for nxt in [src ->:Blocks:->][?:Stage] { if nxt.sid == after { return False; } }
    src +>:Blocks:+> dst;
    return True;
}
def get_parallel_groups(pl: Pipeline, max_parallel: int) -> list[list[str]] {
    stages: list[Stage] = get_all_stages(pl);
    scheduled: dict[str, bool] = {};
    groups: list[list[str]] = [];
    limit: int = max_parallel;
    if limit <= 0 { limit = 1; }
    while len(scheduled) < len(stages) {
        ready: list[Stage] = [];
        for st in stages {
            if st.sid in scheduled { continue; }
            has_unmet: bool = False;
            for cand in stages {
                if cand.sid == st.sid { continue; }
                for nxt in [cand ->:Blocks:->][?:Stage] {
                    if nxt.sid == st.sid { if cand.sid not in scheduled { has_unmet = True; } }
                }
            }
            if not has_unmet { ready.append(st); }
        }
        if len(ready) == 0 { break; }
        ready_ids: list[str] = [];
        for r in ready { ready_ids.append(r.sid); }
        ready_ids = sorted(ready_ids);
        current: list[str] = [];
        for rid in ready_ids {
            current.append(rid);
            if len(current) == limit {
                groups.append(current);
                for cid in current { scheduled[cid] = True; }
                current = [];
            }
        }
        if len(current) > 0 {
            groups.append(current);
            for cid in current { scheduled[cid] = True; }
        }
    }
    return groups;
}
def get_execution_order(pl: Pipeline) -> list[str] {
    groups: list[list[str]] = get_parallel_groups(pl, 1000);
    order: list[str] = [];
    for g in groups { for sid in g { order.append(sid); } }
    return order;
}
def has_cycle(pl: Pipeline) -> bool {
    order: list[str] = get_execution_order(pl);
    stages: list[Stage] = get_all_stages(pl);
    return len(order) != len(stages);
}
def compute_metrics(pl: Pipeline) -> dict[str, int] {
    stages: list[Stage] = get_all_stages(pl);
    seq: int = 0;
    for st in stages { seq += st.duration; }
    groups: list[list[str]] = get_parallel_groups(pl, 2);
    par: int = 0;
    for g in groups {
        max_d: int = 0;
        for sid in g {
            nd = find_stage(pl, sid);
            if nd is not None { if nd.duration > max_d { max_d = nd.duration; } }
        }
        par += max_d;
    }
    res: dict[str, int] = {};
    res["total"] = len(stages);
    res["sequential"] = seq;
    res["parallel"] = par;
    res["groups"] = len(groups);
    return res;
}
with entry {
    demo: Pipeline = make_pipeline("demo");
    add_stage(demo, "security-audit", "security-audit", 2);
    add_stage(demo, "testgen", "testgen", 3);
    add_stage(demo, "build", "build", 1);
    add_dependency(demo, "build", "security-audit");
    w: CollectStages = demo spawn CollectStages(claimed={}, result=[]);
    print(w.result);
    r: CollectStages = root spawn CollectStages(claimed={}, result=[]);
    print(r.result);
}
