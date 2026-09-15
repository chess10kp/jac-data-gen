# Hopac/Hopac#201 — lift recursive job-chain stepping to OSP walkers.

node Job {
    has cid: str;
}

edge Next {}

obj Chain {
    has by_id: dict[str, Job] = {};
}

walker CountDfs {
    has claimed: dict[str, bool] = {};
    has max_iters: int = 0;
    has total: int = 0;

    can step with Job entry {
        if here.cid in self.claimed { skip; }
        if self.total >= self.max_iters { disengage; }
        self.claimed[here.cid] = True;
        self.total += 1;
        print("dfs " + here.cid);
        kids: list[Job] = [];
        for ch in [here ->:Next:->][?:Job] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CountBfs {
    has claimed: dict[str, bool] = {};
    has max_iters: int = 0;
    has total: int = 0;

    can step with Job entry {
        if here.cid in self.claimed { skip; }
        if self.total >= self.max_iters { disengage; }
        self.claimed[here.cid] = True;
        self.total += 1;
        print("bfs " + here.cid);
        kids: list[Job] = [];
        for ch in [here ->:Next:->][?:Job] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker Demo {
    can boot with Root entry {
        ids: list[str] = ["0", "1"];
        edges: list[tuple[str, str]] = [("0", "1")];
        ch = build_chain(ids, edges);
        n = run_loop(ch, "0", 100000);
        print(n);
        disengage;
    }
}

def build_chain(nodes: list[str], edges: list[tuple[str, str]]) -> Chain {
    c = Chain(by_id={});
    for nid in nodes {
        nd = Job(cid=nid);
        root ++> nd;
        c.by_id[nid] = nd;
    }
    for edge in edges {
        fr = edge[0];
        to = edge[1];
        if fr in c.by_id and to in c.by_id {
            a = c.by_id[fr];
            b = c.by_id[to];
            a +>: Next:+> b;
        }
    }
    return c;
}

def run_recursive(c: Chain, start: str, max_iters: int) -> int {
    if start not in c.by_id {
        return 0;
    }
    nd = c.by_id[start];
    w = nd spawn CountDfs(claimed={}, max_iters=max_iters, total=0);
    return w.total;
}

def run_loop(c: Chain, start: str, max_iters: int) -> int {
    if start not in c.by_id {
        return 0;
    }
    nd = c.by_id[start];
    w = nd spawn CountBfs(claimed={}, max_iters=max_iters, total=0);
    return w.total;
}

with entry {
    root spawn Demo();
}

test "loop_counts_chain" {
    ch = build_chain(["0", "1"], [("0", "1")]);
    assert run_loop(ch, "0", 10) == 2;
}

test "recursive_counts_chain" {
    ch = build_chain(["0", "1"], [("0", "1")]);
    assert run_recursive(ch, "0", 10) == 2;
}

test "max_iters_caps_loop" {
    ch = build_chain(["0", "1", "2"], [("0", "1"), ("1", "2")]);
    assert run_loop(ch, "0", 1) == 1;
}

test "unknown_start_returns_zero" {
    ch = build_chain(["0", "1"], [("0", "1")]);
    assert run_loop(ch, "missing", 10) == 0;
    assert run_recursive(ch, "missing", 10) == 0;
}

test "dfs_bfs_same_on_chain" {
    ids: list[str] = ["0", "1", "2"];
    edges: list[tuple[str, str]] = [("0", "1"), ("1", "2")];
    ch = build_chain(ids, edges);
    assert run_recursive(ch, "0", 10) == run_loop(ch, "0", 10);
}
