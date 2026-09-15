"""DSA syllabus progress tracker — darshjaiswal58-a11y/DSA-interview-prep-1#1."""

node Topic {
    has tid: str;
    has title: str;
    has status: str = "pending";
    has section: int = 0;
}

edge Child {}
edge Prereq {}

def sort_topics(kids: list[Topic]) -> list[Topic] {
    out: list[Topic] = [];
    for k in kids { out.append(k); }
    for i in range(len(out)) {
        for j in range(i + 1, len(out)) {
            swap: bool = False;
            if out[j].section < out[i].section { swap = True; }
            elif out[j].section == out[i].section and out[j].tid < out[i].tid { swap = True; }
            if swap {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
        }
    }
    return out;
}

def child_neighbors(topic: Topic) -> list[Topic] {
    kids: list[Topic] = [];
    for ch in [topic ->:Child:->][?:Topic] { kids.append(ch); }
    return sort_topics(kids);
}

def closure_neighbors(topic: Topic) -> list[Topic] {
    nbrs: list[Topic] = [];
    for ch in [topic ->:Child:->][?:Topic] { nbrs.append(ch); }
    for pr in [topic ->:Prereq:->][?:Topic] { nbrs.append(pr); }
    return sort_topics(nbrs);
}

walker ChildBfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print(here.tid);
        visit child_neighbors(here);
    }
}

walker ChildDfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print(here.tid);
        visit :0: child_neighbors(here);
    }
}

walker ClosureBfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print(here.tid);
        visit closure_neighbors(here);
    }
}

walker FindTopicWalk {
    has claimed: dict[str, bool] = {};
    has want: str = "";
    has hit: bool = False;
    has target: Topic | None = None;

    can step with Topic entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid == self.want {
            self.hit = True;
            self.target = here;
            disengage;
        }
        kids: list[Topic] = child_neighbors(here);
        visit kids else { disengage; }
    }
}

walker StatusCountWalk {
    has claimed: dict[str, bool] = {};
    has tally: int = 0;
    has target: str = "";

    can tally_step with Topic entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.status == self.target { self.tally += 1; }
        kids: list[Topic] = child_neighbors(here);
        visit kids else { disengage; }
    }
}

def build_syllabus_root -> Topic {
    r = Topic(tid="syllabus", title="DSA Syllabus", status="current", section=0);
    fnd = Topic(tid="foundations", title="Foundations", status="completed", section=1);
    arr = Topic(tid="arrays", title="Arrays", status="completed", section=2);
    grf = Topic(tid="graphs", title="Graphs", status="pending", section=17);
    tcm = Topic(tid="time_complexity", title="Time & Space Complexity", status="completed", section=1);
    rec = Topic(tid="recursion", title="Recursion basics", status="completed", section=1);
    atr = Topic(tid="array_traversal", title="Array traversal", status="completed", section=2);
    gbf = Topic(tid="graph_bfs", title="BFS", status="pending", section=17);
    gdf = Topic(tid="graph_dfs", title="DFS traversals", status="pending", section=17);
    r +>:Child:+> fnd;
    r +>:Child:+> arr;
    r +>:Child:+> grf;
    fnd +>:Child:+> tcm;
    fnd +>:Child:+> rec;
    arr +>:Child:+> atr;
    grf +>:Child:+> gbf;
    grf +>:Child:+> gdf;
    rec +>:Prereq:+> gdf;
    gbf +>:Prereq:+> gdf;
    return r;
}

def child_bfs_ids(root_node: Topic) -> list[str] {
    w = root_node spawn ChildBfsWalk;
    return w.order;
}

def child_dfs_preorder_ids(root_node: Topic) -> list[str] {
    w = root_node spawn ChildDfsWalk;
    return w.order;
}

def prereq_closure_bfs_ids(root_node: Topic) -> list[str] {
    w = root_node spawn ClosureBfsWalk;
    return w.order;
}

def count_status(root_node: Topic, status: str) -> int {
    w = root_node spawn StatusCountWalk(target=status);
    return w.tally;
}

def set_completed(root_node: Topic, tid: str) -> bool {
    w = root_node spawn FindTopicWalk(want=tid);
    if not w.hit { return False; }
    w.target.status = "completed";
    return True;
}

def get_status(root_node: Topic, tid: str) -> str | None {
    w = root_node spawn FindTopicWalk(want=tid);
    if not w.hit { return None; }
    return w.target.status;
}

with entry {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    demo = graph_root spawn ChildBfsWalk;
    print(demo.order);
}

test "child_bfs_order" {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    got = child_bfs_ids(graph_root);
    exp: list[str] = ["syllabus", "foundations", "arrays", "graphs", "recursion", "time_complexity", "array_traversal", "graph_bfs", "graph_dfs"];
    assert got == exp;
}

test "child_dfs_preorder" {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    got = child_dfs_preorder_ids(graph_root);
    exp: list[str] = ["syllabus", "foundations", "recursion", "time_complexity", "arrays", "array_traversal", "graphs", "graph_bfs", "graph_dfs"];
    assert got == exp;
}

test "closure_bfs_matches_child_bfs" {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    child_ids = child_bfs_ids(graph_root);
    closure_ids = prereq_closure_bfs_ids(graph_root);
    assert closure_ids == child_ids;
}

test "count_status_completed" {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    assert count_status(graph_root, "completed") == 5;
    assert count_status(graph_root, "pending") == 3;
    assert count_status(graph_root, "current") == 1;
}

test "set_and_get_status" {
    graph_root = build_syllabus_root();
    root ++> graph_root;
    assert set_completed(graph_root, "graphs") == True;
    assert get_status(graph_root, "graphs") == "completed";
    assert set_completed(graph_root, "missing_topic") == False;
    assert get_status(graph_root, "missing_topic") == None;
}
