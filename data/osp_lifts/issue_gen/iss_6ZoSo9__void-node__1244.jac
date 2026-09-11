# iss_6ZoSo9__void-node__1244.jac — Dijkstra state-machine audit (6ZoSo9/void-node#1244)
node AuditRoot { has cid: str; }
node StateMachine { has cid: str; has lane: str = ""; has occupied: bool = False; }
node Finding { has cid: str; has impact: int = 0; has occupied: bool = False; has reachable: bool = True; }
edge Contains {}
edge Owns {}

walker InventoryWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can start with AuditRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("finder root");
        kids: list[StateMachine] = [here ->:Contains:->][?:StateMachine];
        for k in kids {
            visit :0: [k];
        }
        if len(kids) == 0 { disengage; }
    }
    can handle_machine with StateMachine entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("finder machine " + here.cid);
        self.result.append(here.cid);
        next_ms: list[StateMachine] = [here ->:Contains:->][?:StateMachine];
        for n in next_ms { visit :0: [n]; }
        owns: list[Finding] = [here ->:Owns:->][?:Finding];
        for f in owns { visit :0: [f]; }
        if len(next_ms) == 0 and len(owns) == 0 { disengage; }
    }
    can handle_finding with Finding entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
    }
}

walker RankWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[Finding] = [];
    can start_rank with AuditRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("rank root");
        kids: list[StateMachine] = [here ->:Contains:->][?:StateMachine];
        for k in kids { visit :0: [k]; }
        if len(kids) == 0 { disengage; }
    }
    can step_machine with StateMachine entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("rank machine " + here.cid);
        if here.occupied {
            next_ms: list[StateMachine] = [here ->:Contains:->][?:StateMachine];
            for n in next_ms { visit :0: [n]; }
            if len(next_ms) == 0 { disengage; }
        } else {
            next_ms: list[StateMachine] = [here ->:Contains:->][?:StateMachine];
            for n in next_ms { visit :0: [n]; }
            owns: list[Finding] = [here ->:Owns:->][?:Finding];
            for f in owns { visit :0: [f]; }
            if len(next_ms) == 0 and len(owns) == 0 { disengage; }
        }
    }
    can step_finding with Finding entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("rank fid " + here.cid);
        if here.occupied { skip; }
        if not here.reachable { skip; }
        self.collected.append(here);
    }
}

def make_audit(aid: str) -> AuditRoot {
    rt = AuditRoot(cid=aid);
    root ++> rt;
    return rt;
}

def add_machine(root_node: AuditRoot, mid: str, lane: str = "", occupied: bool = False) -> StateMachine {
    # lane may carry bool when caller uses positional occupied
    real_occupied: bool = occupied;
    real_lane: str = lane;
    m = StateMachine(cid=mid, lane=real_lane, occupied=real_occupied);
    root_node +>:Contains:+> m;
    return m;
}

def add_state_machine(root_node: AuditRoot, mid: str, lane: str = "", occupied: bool = False) -> StateMachine {
    return add_machine(root_node, mid, lane, occupied);
}

def add_finding(root_node: AuditRoot, fid: str, mid: str, impact: int = 0, occupied: bool = False, reachable: bool = True) -> Finding | None {
    targets: list[StateMachine] = [root_node ->:Contains:->][?:StateMachine];
    # also consider transitive machines for diamond reach
    # collect via walker for broader search if direct miss
    found: StateMachine | None = None;
    for m in targets {
        if m.cid == mid { found = m; }
    }
    if found == None {
        w = root_node spawn InventoryWalker(claimed={}, result=[]);
        # second pass: walk all reachable machines via traversal
        # fallback linear scan over walker result not needed, do BFS via edges
        all_ms: list[StateMachine] = [];
        # collect via secondary navigation: check machine->machine
        for m in targets {
            deeper: list[StateMachine] = [m ->:Contains:->][?:StateMachine];
            for d in deeper { targets.append(d); }
        }
        for m in targets {
            if m.cid == mid { found = m; }
        }
    }
    if found == None { return None; }
    f = Finding(cid=fid, impact=impact, occupied=occupied, reachable=reachable);
    found +>:Owns:+> f;
    return f;
}

def inventory_machines(root_node: AuditRoot) -> list[str] {
    w = root_node spawn InventoryWalker(claimed={}, result=[]);
    return sorted(w.result);
}

def inventory_state_machines(root_node: AuditRoot) -> list[str] {
    return inventory_machines(root_node);
}

def rank_candidates(root_node: AuditRoot) -> list[str] {
    w = root_node spawn RankWalker(claimed={}, collected=[]);
    # sort collected descending by impact
    n: int = len(w.collected);
    for i in range(0, n) {
        for j in range(i + 1, n) {
            if w.collected[j].impact > w.collected[i].impact {
                tmp: Finding = w.collected[i];
                w.collected[i] = w.collected[j];
                w.collected[j] = tmp;
            }
        }
    }
    out: list[str] = [];
    cnt: int = 0;
    for f in w.collected {
        if cnt < 3 {
            out.append(f.cid);
            cnt += 1;
        }
    }
    return sorted(out);
}

def rank_findings(root_node: AuditRoot) -> list[str] {
    return rank_candidates(root_node);
}

with entry {
    rt = AuditRoot(cid="demo");
    root ++> rt;
    m = StateMachine(cid="demo-m1");
    rt +>:Contains:+> m;
    f = Finding(cid="demo-f1", impact=10);
    m +>:Owns:+> f;
    inv = rt spawn InventoryWalker(claimed={}, result=[]);
    print(inv.result);
    rk = rt spawn RankWalker(claimed={}, collected=[]);
    print(rk.collected);
}
