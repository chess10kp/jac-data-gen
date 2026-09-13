node GraphRoot { has name: str; }
node Lane { has lane_id: str; has slot: int; has pulses: int = 0; has retired: bool = False; }
node Task { has tid: str; has lane_id: str; has status: str = "pending"; }
node Chat { has chat_id: str; has slot: int; has pulses: int = 0; }

edge Contains {}
edge Depends {}
edge Owns {}

walker DepCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Task] = [];
    can collect with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here);
        print(here.tid);
        for dep in [here ->:Depends:->][?:Task] {
            visit :0: [dep];
        }
    }
}

def find_task(graph_root: GraphRoot, tid: str) -> Task | None {
    for t in [graph_root ->:Contains:->][?:Task] {
        if t.tid == tid { return t; }
    }
    return None;
}
def find_lane(graph_root: GraphRoot, lane_id: str) -> Lane | None {
    for l in [graph_root ->:Contains:->][?:Lane] {
        if l.lane_id == lane_id { return l; }
    }
    return None;
}
def find_lane_by_slot(graph_root: GraphRoot, slot: int) -> Lane | None {
    for l in [graph_root ->:Contains:->][?:Lane] {
        if l.slot == slot { return l; }
    }
    return None;
}
def find_chat_by_slot(graph_root: GraphRoot, slot: int) -> Chat | None {
    for c in [graph_root ->:Contains:->][?:Chat] {
        if c.slot == slot { return c; }
    }
    return None;
}
def new_graph(name: str) -> GraphRoot {
    gr = GraphRoot(name=name);
    return gr;
}
def add_lane(graph_root: GraphRoot, lane_id: str, slot: int) -> Lane {
    l = Lane(lane_id=lane_id, slot=slot);
    graph_root +>:Contains:+> l;
    return l;
}
def add_chat(graph_root: GraphRoot, chat_id: str, slot: int) -> Chat {
    c = Chat(chat_id=chat_id, slot=slot);
    graph_root +>:Contains:+> c;
    return c;
}
def add_task(graph_root: GraphRoot, tid: str, lane_id: str) -> Task | None {
    existing: Task | None = find_task(graph_root, tid);
    if existing is not None { return existing; }
    t = Task(tid=tid, lane_id=lane_id);
    graph_root +>:Contains:+> t;
    lane: Lane | None = find_lane(graph_root, lane_id);
    if lane is not None {
        lane +>:Owns:+> t;
    }
    return t;
}
def add_depends(graph_root: GraphRoot, from_tid: str, to_tid: str) -> bool {
    a: Task | None = find_task(graph_root, from_tid);
    b: Task | None = find_task(graph_root, to_tid);
    if a is None { return False; }
    if b is None { return False; }
    for d in [a ->:Depends:->][?:Task] {
        if d.tid == to_tid { return True; }
    }
    a +>:Depends:+> b;
    return True;
}
def mark_done(graph_root: GraphRoot, tid: str) -> bool {
    t: Task | None = find_task(graph_root, tid);
    if t is None { return False; }
    t.status = "done";
    return True;
}
def get_transitive_deps(graph_root: GraphRoot, tid: str) -> list[str] {
    t: Task | None = find_task(graph_root, tid);
    if t is None { return []; }
    deps: list[Task] = [t ->:Depends:->][?:Task];
    if len(deps) == 0 { return []; }
    w = t spawn DepCollect(claimed={});
    ids: list[str] = [];
    for n in w.found {
        if n.tid != tid { ids.append(n.tid); }
    }
    return sorted(ids);
}
def get_eligible_tasks(graph_root: GraphRoot) -> list[str] {
    out: list[str] = [];
    for t in [graph_root ->:Contains:->][?:Task] {
        if t.status != "pending" { continue; }
        ok: bool = True;
        for d in [t ->:Depends:->][?:Task] {
            if d.status != "done" { ok = False; }
        }
        if ok { out.append(t.tid); }
    }
    return sorted(out);
}
def get_lane_tasks(graph_root: GraphRoot, lane_id: str) -> list[str] {
    lane: Lane | None = find_lane(graph_root, lane_id);
    if lane is None { return []; }
    ids: list[str] = [];
    for t in [lane ->:Owns:->][?:Task] {
        ids.append(t.tid);
    }
    return sorted(ids);
}
def advance_pulse(graph_root: GraphRoot, slot: int) -> dict[str, int] {
    lane: Lane | None = find_lane_by_slot(graph_root, slot);
    chat: Chat | None = find_chat_by_slot(graph_root, slot);
    pulses: int = 0;
    retired: int = 0;
    if lane is not None {
        lane.pulses = lane.pulses + 1;
        if lane.pulses >= 20 { lane.retired = True; }
        pulses = lane.pulses;
        if lane.retired { retired = 1; }
    }
    if chat is not None {
        chat.pulses = chat.pulses + 1;
    }
    res: dict[str, int] = {"pulses": pulses, "retired": retired};
    return res;
}
