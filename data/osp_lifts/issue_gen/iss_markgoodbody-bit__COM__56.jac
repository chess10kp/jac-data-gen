node Task { has tid: str; has queued_at: int = 0; has not_after: int = 0; }
node GraphRoot { has name: str = "root"; }
edge Contains {}
edge Depends {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has limit: int = 10;
    has cur_depth: dict[str, int] = {};
    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        print(here.tid);
        cur: int = 0;
        if here.tid in self.cur_depth {
            cur = self.cur_depth[here.tid];
        }
        if cur >= self.limit {
            # depth limit reached, do not expand
        } else {
            for nxt in [here ->:Depends:->][?: Task] {
                if nxt.tid not in self.cur_depth {
                    self.cur_depth[nxt.tid] = cur + 1;
                } else {
                    if cur + 1 < self.cur_depth[nxt.tid] {
                        self.cur_depth[nxt.tid] = cur + 1;
                    }
                }
                visit [nxt];
            }
        }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can start with GraphRoot entry {
        print("demo start " + here.name);
        for t in [here ->:Contains:->][?: Task] {
            visit [t];
        }
    }
    can step_task with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(here.tid);
        for nxt in [here ->:Depends:->][?: Task] {
            visit [nxt];
        }
    }
}

def find_task(root_node: GraphRoot, tid: str) -> Task | None {
    for t in [root_node ->:Contains:->][?: Task] {
        if t.tid == tid {
            return t;
        }
    }
    return None;
}

def add_task(root_node: GraphRoot, tid: str, queued_at: int, not_after: int) -> Task | None {
    existing: Task | None = find_task(root_node, tid);
    if existing is not None {
        return existing;
    }
    nd: Task = Task(tid=tid, queued_at=queued_at, not_after=not_after);
    root_node +>:Contains:+> nd;
    return nd;
}

def add_dependency(root_node: GraphRoot, from_tid: str, to_tid: str) -> bool {
    src: Task | None = find_task(root_node, from_tid);
    dst: Task | None = find_task(root_node, to_tid);
    if src is None { return False; }
    if dst is None { return False; }
    s: Task = src;
    d: Task = dst;
    for nxt in [s ->:Depends:->][?: Task] {
        if nxt.tid == to_tid { return True; }
    }
    s +>:Depends:+> d;
    return True;
}

def reachable_ids(root_node: GraphRoot, start_tid: str, max_depth: int) -> list[str] {
    start: Task | None = find_task(root_node, start_tid);
    if start is None { return []; }
    if max_depth < 0 { return []; }
    s: Task = start;
    cur_map: dict[str, int] = {};
    cur_map[start_tid] = 0;
    w: ReachWalker = s spawn ReachWalker(limit=max_depth, cur_depth=cur_map);
    res: list[str] = sorted(w.found);
    return res;
}

def is_authorized(root_node: GraphRoot, tid: str, now: int) -> bool {
    t: Task | None = find_task(root_node, tid);
    if t is None { return False; }
    tt: Task = t;
    if tt.not_after == 0 { return True; }
    return now <= tt.not_after;
}

with entry {
    g: GraphRoot = GraphRoot(name="demo");
    a: Task = Task(tid="A", queued_at=0, not_after=0);
    b: Task = Task(tid="B", queued_at=0, not_after=10);
    g +>:Contains:+> a;
    g +>:Contains:+> b;
    a +>:Depends:+> b;
    w: DemoWalker = g spawn DemoWalker(claimed={});
    print("demo done");
}
