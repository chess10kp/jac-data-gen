"""vllm-project/vllm-omni#6296 — NPU Moss-TTS work-item dependency planner (OSP lift)."""

obj NpuPlan {
    has items: list[str] = [];
    has preds: dict[str, list[str]] = {};

    def load(items: list[str], edges: list[tuple[str, str]]) -> None;
    def downstream_impact(stage_id: str) -> list[str];
    def eligible_claims(done: set[str]) -> list[str];
}

node WorkItem {
    has wid: str;
}

edge Requires {}

walker DownstreamWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        for w in [-->][?:WorkItem] {
            if w.wid == self.origin {
                visit [w];
            }
        }
    }

    can step with WorkItem entry {
        if here.wid in self.claimed {
            skip;
        }
        self.claimed[here.wid] = True;
        if here.wid != self.origin {
            self.hits.append(here.wid);
        }
        visit [->:Requires:->];
    }
}

impl NpuPlan.load(items: list[str], edges: list[tuple[str, str]]) -> None {
    self.items = items;
    self.preds = {};
    mp: dict[str, WorkItem] = {};
    for it in items {
        self.preds[it] = [];
        if it not in mp {
            n = WorkItem(wid=it);
            root ++> n;
            mp[it] = n;
        }
    }
    for (pre, dep) in edges {
        if pre in mp and dep in mp {
            mp[pre] +>:Requires:+> mp[dep];
            self.preds[dep].append(pre);
        }
    }
}

impl NpuPlan.downstream_impact(stage_id: str) -> list[str] {
    if stage_id not in self.preds {
        return [];
    }
    w = root spawn DownstreamWalker(origin=stage_id, claimed={}, hits=[]);
    return sorted(w.hits);
}

impl NpuPlan.eligible_claims(done: set[str]) -> list[str] {
    out: list[str] = [];
    for it in sorted(self.items) {
        if it in done {
            continue;
        }
        ok = True;
        for pre in self.preds.get(it, []) {
            if pre not in done {
                ok = False;
            }
        }
        if ok {
            out.append(it);
        }
    }
    return out;
}
