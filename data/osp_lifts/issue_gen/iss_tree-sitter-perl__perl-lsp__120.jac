"""tree-sitter-perl/perl-lsp#120 — iterative builder walk replacing CST recursion."""

node Task {
    has cid: str;
    has kind: str = "cst";
    has depth: int = 0;
}

edge Child {}

obj TaskGraph {
    has root_id: str = "";
    has root: Task;
    has by_id: dict[str, Task] = {};
}

walker BuilderWalk {
    has claimed: dict[str, bool] = {};
    has max_depth: int = -1;
    has order: list[str] = [];

    can step with Task entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print {"builder": here.cid, "depth": here.depth};
        if self.max_depth >= 0 and here.depth >= self.max_depth {
            disengage;
        }
        kids: list[Task] = [];
        for ch in [here ->:Child:->][?:Task] {
            kids.append(ch);
        }
        i: int = 0;
        while i < len(kids) {
            j: int = i + 1;
            while j < len(kids) {
                if kids[j].cid < kids[i].cid {
                    tmp: Task = kids[i];
                    kids[i] = kids[j];
                    kids[j] = tmp;
                }
                j += 1;
            }
            i += 1;
        }
        rev: list[Task] = [];
        idx: int = len(kids) - 1;
        while idx >= 0 {
            rev.append(kids[idx]);
            idx -= 1;
        }
        if rev {
            visit :0: rev;
        } else {
            disengage;
        }
    }
}

def make_task_graph(specs: list, parent_child: list) -> TaskGraph {
    g = TaskGraph();
    for spec in specs {
        tid: str = spec[0];
        kind: str = spec[1];
        dep: int = spec[2];
        nd = Task(cid=tid, kind=kind, depth=dep);
        g.by_id[tid] = nd;
    }
    if specs {
        g.root_id = specs[0][0];
        g.root = g.by_id[g.root_id];
    }
    for pc in parent_child {
        p: str = pc[0];
        c: str = pc[1];
        if p not in g.by_id {
            continue;
        }
        if c not in g.by_id {
            continue;
        }
        pa: Task = g.by_id[p];
        ch: Task = g.by_id[c];
        pa +>:Child:+> ch;
    }
    return g;
}

def iter_builder_order(g: TaskGraph, max_depth: int = -1) -> list[str] {
    w = g.root spawn BuilderWalk(claimed={}, max_depth=max_depth);
    return w.order;
}

def tail_task_ids(g: TaskGraph, depth_limit: int) -> list[str] {
    ids: list[str] = [];
    for tid in g.by_id {
        nd: Task = g.by_id[tid];
        if nd.depth >= depth_limit {
            ids.append(tid);
        }
    }
    ids = sorted(ids);
    return ids;
}

def session_assignments(task_ids: list[str], sessions: list[str]) -> dict[str, list[str]] {
    out: dict[str, list[str]] = {};
    for s in sessions {
        out[s] = [];
    }
    ordered: list[str] = [];
    for tid in task_ids {
        ordered.append(tid);
    }
    ordered = sorted(ordered);
    i: int = 0;
    for tid in ordered {
        sl: str = sessions[i % len(sessions)];
        out[sl].append(tid);
        i += 1;
    }
    return out;
}
