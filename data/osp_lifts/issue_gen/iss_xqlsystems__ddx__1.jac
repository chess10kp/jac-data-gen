"""xqlsystems/ddx#1 — plan rewrite reachability (OSP lift)."""

glob UNSUPPORTED: list[str] = ["recursive_cte", "dml", "scalar_subquery"];

obj PlanStore {
    has kinds: dict[str, str] = {};
    has edges: dict[str, list[str]] = {};
    has max_depth: int = 64;
}

node PlanNode { has pid: str; has kind: str; }
edge PlanEdge {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth: int = 0;
    has cap: int = 64;
    has plan_ids: dict[str, bool] = {};

    can step with PlanNode entry {
        if here.pid in self.claimed { skip; }
        if self.depth >= self.cap { skip; }
        self.claimed[here.pid] = True;
        if here.pid in self.plan_ids {
            self.reached.append(here.pid);
        }
        self.depth += 1;
        visit [->:PlanEdge:->] else { disengage; };
    }
}

def _find(pid: str) -> PlanNode | None {
    for n in [-->][?:PlanNode] { if n.pid == pid { return n; } }
    return None;
}

def load_plan(kinds: dict[str, str], edges: dict[str, list[str]], max_depth: int = 64) -> PlanStore {
    mp: dict[str, PlanNode] = {};
    ids: dict[str, bool] = {};
    for pid in kinds { ids[pid] = True; }
    for (src, tgts) in edges.items() {
        ids[src] = True;
        for tgt in tgts { ids[tgt] = True; }
    }
    for pid in ids {
        fresh = PlanNode(pid=pid, kind=kinds.get(pid, ""));
        root ++> fresh;
        mp[pid] = fresh;
    }
    for (src, tgts) in edges.items() {
        a = mp.get(src, None);
        if a is None { continue; }
        for tgt in tgts {
            b = mp.get(tgt, None);
            if b is not None { a +>:PlanEdge():+> b; }
        }
    }
    return PlanStore(kinds=kinds, edges=edges, max_depth=max_depth);
}

def can_substrait_emit(g: PlanStore, pid: str) -> bool {
    return g.kinds.get(pid, "") not in UNSUPPORTED;
}

def recursive_reach(g: PlanStore, root_id: str) -> list[str] {
    if root_id not in g.kinds and root_id not in g.edges { return []; }
    anchor = _find(root_id);
    if anchor is None { return []; }
    plan_ids: dict[str, bool] = {};
    for pid in g.kinds { plan_ids[pid] = True; }
    w = anchor spawn ReachWalk(
        claimed={}, reached=[], depth=0, cap=g.max_depth, plan_ids=plan_ids
    );
    return sorted(w.reached);
}
