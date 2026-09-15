"""Connect4 multicore negamax coarse dispatch — iteathen/Connect4#13."""

node SearchPos {
    has cid: str;
    has board_bits: int = 0;
    has player: int = 1;
    has leaf_score: int = 0;
}

edge PlayMove {
    has col: int = 0;
}

walker NegamaxW {
    has claimed: dict[str, bool] = {};
    has depth_limit: int = 0;
    has found: dict[str, int] = {};

    can search with SearchPos entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if self.depth_limit <= 0 {
            self.found[here.cid] = here.leaf_score;
            print({"op": "leaf", "cid": here.cid, "score": here.leaf_score});
            disengage;
        }
        kids: list[SearchPos] = [];
        for ch in [here ->:PlayMove:->][?:SearchPos] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            self.found[here.cid] = here.leaf_score;
            print({"op": "term", "cid": here.cid, "score": here.leaf_score});
            disengage;
        }
        best_child: int = -1000000;
        for kid in kids {
            sub = kid spawn NegamaxW(claimed={}, depth_limit=self.depth_limit - 1, found={});
            kid_score: int = 0;
            if kid.cid in sub.found {
                kid_score = sub.found[kid.cid];
            }
            cand: int = -kid_score;
            if cand > best_child {
                best_child = cand;
            }
        }
        self.found[here.cid] = best_child;
        print({"op": "negamax", "cid": here.cid, "score": self.found[here.cid]});
        disengage;
    }
}

walker TaskPlanW {
    has claimed: dict[str, bool] = {};
    has worker_budget: int = 1;
    has tasks: list[str] = [];

    can plan with SearchPos entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        kids: list[SearchPos] = [];
        for ch in [here ->:PlayMove:->][?:SearchPos] {
            kids.append(ch);
        }
        if self.worker_budget <= 1 or len(kids) == 0 {
            self.tasks.append(here.cid);
            print({"op": "task", "cid": here.cid});
            disengage;
        }
        for kid in kids {
            self.tasks.append(kid.cid);
            print({"op": "shard", "cid": kid.cid});
        }
        disengage;
    }
}

walker FindPosW {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has hit: SearchPos | None = None;

    can seek with SearchPos entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = here;
            print({"op": "hit", "cid": here.cid});
            disengage;
        }
        kids: list[SearchPos] = [];
        for ch in [here ->:PlayMove:->][?:SearchPos] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        }
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def detect_cpu_capacity() -> int {
    return 4;
}

def make_search_pos(board_bits: int, player: int, leaf_score: int) -> SearchPos {
    cid: str = "pos_" + str(board_bits);
    nd = SearchPos(cid=cid, board_bits=board_bits, player=player, leaf_score=leaf_score);
    root ++> nd;
    return nd;
}

def link_move(parent: SearchPos, child: SearchPos, col: int) -> None {
    parent +>:PlayMove(col=col):+> child;
}

def find_pos_by_cid(start: SearchPos, target_cid: str) -> SearchPos | None {
    wk = start spawn FindPosW(claimed={}, target=target_cid, hit=None);
    return wk.hit;
}

def negamax(position: SearchPos, depth: int) -> int {
    wk = position spawn NegamaxW(claimed={}, depth_limit=depth, found={});
    if position.cid in wk.found {
        return wk.found[position.cid];
    }
    return 0;
}

def negamax_by_cid(start: SearchPos, cid: str, depth: int) -> int {
    target: SearchPos | None = find_pos_by_cid(start, cid);
    if target is None {
        return 0;
    }
    return negamax(target, depth);
}

def plan_coarse_tasks(root_pos: SearchPos, active_workers: int) -> list[str] {
    budget: int = active_workers;
    if budget < 1 {
        budget = 1;
    }
    wk = root_pos spawn TaskPlanW(claimed={}, worker_budget=budget, tasks=[]);
    out: list[str] = sorted(wk.tasks);
    return out;
}

def run_parallel_negamax(root_pos: SearchPos, active_workers: int) -> dict[str, int] {
    shards: list[str] = plan_coarse_tasks(root_pos, active_workers);
    merged: dict[str, int] = {};
    for shard_cid in shards {
        node_ref: SearchPos | None = find_pos_by_cid(root_pos, shard_cid);
        if node_ref is None {
            continue;
        }
        merged[shard_cid] = negamax(node_ref, 2);
    }
    merged[root_pos.cid] = negamax(root_pos, 3);
    return merged;
}
