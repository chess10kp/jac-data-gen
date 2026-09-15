# iss_dsa-collective__algorithm-pattern-classifier__18.jac
# BFSDetector / DFSDetector / PatternClassifier — OSP lift for dsa-collective/algorithm-pattern-classifier#18

node Snippet {
    has cid: str;
    has tag: str;
}

edge Flow {}

walker BfsScan {
    has claimed: dict[str, bool] = {};
    has hits: int = 0;

    can step with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.tag == "queue_init" {
            self.hits = self.hits + 1;
        }
        if here.tag == "while_queue" {
            self.hits = self.hits + 1;
        }
        if here.tag == "popleft" {
            self.hits = self.hits + 1;
        }
        if here.tag == "queue_append" {
            self.hits = self.hits + 1;
        }
        print(self.hits);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker DfsScan {
    has claimed: dict[str, bool] = {};
    has iterative: bool = False;
    has recursive: bool = False;
    has memo: bool = False;

    can step with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.tag == "stack_init" {
            self.iterative = True;
        }
        if here.tag == "while_stack" {
            self.iterative = True;
        }
        if here.tag == "stack_pop" {
            self.iterative = True;
        }
        if here.tag == "recurse_self" {
            self.recursive = True;
        }
        if here.tag == "memo" {
            self.memo = True;
        }
        print(self.recursive);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker IdFind {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found: Snippet | None = None;

    can hunt with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target_id {
            self.found = here;
        }
        print(self.target_id);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

def bfs_confidence(graph_root: Snippet) -> float {
    w = graph_root spawn BfsScan(claimed={});
    if w.hits >= 4 {
        return 0.85;
    }
    part: float = (w.hits * 1.0) / 4.0;
    return part * 0.75;
}

def dfs_profile(graph_root: Snippet) -> dict[str, bool] {
    w = graph_root spawn DfsScan(claimed={});
    out: dict[str, bool] = {};
    out["iterative"] = w.iterative;
    out["recursive"] = w.recursive;
    out["memo"] = w.memo;
    return out;
}

def find_snippet_by_id(graph_root: Snippet, snippet_id: str) -> Snippet | None {
    wk = graph_root spawn IdFind(target_id=snippet_id, claimed={}, found=None);
    return wk.found;
}

def classify_pattern(graph_root: Snippet) -> str {
    bfs_val = bfs_confidence(graph_root);
    dfs_map = dfs_profile(graph_root);
    if dfs_map["memo"] and dfs_map["recursive"] {
        return "DP";
    }
    if bfs_val > 0.8 {
        return "BFS";
    }
    if dfs_map["iterative"] or dfs_map["recursive"] {
        return "DFS";
    }
    return "UNKNOWN";
}

# iss_dsa-collective__algorithm-pattern-classifier__18_guard.jac
# BFSDetector / DFSDetector / PatternClassifier — OSP lift for dsa-collective/algorithm-pattern-classifier#18

node Snippet {
    has cid: str;
    has tag: str;
}

edge Flow {}

walker BfsScan {
    has claimed: dict[str, bool] = {};
    has hits: int = 0;

    can step with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.tag == "queue_init" {
            self.hits = self.hits + 1;
        }
        if here.tag == "while_queue" {
            self.hits = self.hits + 1;
        }
        if here.tag == "popleft" {
            self.hits = self.hits + 1;
        }
        if here.tag == "queue_append" {
            self.hits = self.hits + 1;
        }
        print(self.hits);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker DfsScan {
    has claimed: dict[str, bool] = {};
    has iterative: bool = False;
    has recursive: bool = False;
    has memo: bool = False;

    can step with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.tag == "stack_init" {
            self.iterative = True;
        }
        if here.tag == "while_stack" {
            self.iterative = True;
        }
        if here.tag == "stack_pop" {
            self.iterative = True;
        }
        if here.tag == "recurse_self" {
            self.recursive = True;
        }
        if here.tag == "memo" {
            self.memo = True;
        }
        print(self.recursive);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker IdFind {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found: Snippet | None = None;

    can hunt with Snippet entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target_id {
            self.found = here;
        }
        print(self.target_id);
        kids: list[Snippet] = [];
        for nxt in [here ->:Flow:->][?:Snippet] {
            kids.append(nxt);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

def bfs_confidence(graph_root: Snippet) -> float {
    w = graph_root spawn BfsScan(claimed={});
    if w.hits >= 4 {
        return 0.85;
    }
    part: float = (w.hits * 1.0) / 4.0;
    return part * 0.75;
}

def dfs_profile(graph_root: Snippet) -> dict[str, bool] {
    w = graph_root spawn DfsScan(claimed={});
    out: dict[str, bool] = {};
    out["iterative"] = w.iterative;
    out["recursive"] = w.recursive;
    out["memo"] = w.memo;
    return out;
}

def find_snippet_by_id(graph_root: Snippet, snippet_id: str) -> Snippet | None {
    wk = graph_root spawn IdFind(target_id=snippet_id, claimed={}, found=None);
    return wk.found;
}

def classify_pattern(graph_root: Snippet) -> str {
    bfs_val = bfs_confidence(graph_root);
    dfs_map = dfs_profile(graph_root);
    if dfs_map["memo"] and dfs_map["recursive"] {
        return "DP";
    }
    if bfs_val > 0.8 {
        return "BFS";
    }
    if dfs_map["iterative"] or dfs_map["recursive"] {
        return "DFS";
    }
    return "UNKNOWN";
}

test "bfs_confidence_full_chain" {
    graph_root = Snippet(cid="r", tag="root");
    n1 = Snippet(cid="n1", tag="queue_init");
    n2 = Snippet(cid="n2", tag="while_queue");
    n3 = Snippet(cid="n3", tag="popleft");
    n4 = Snippet(cid="n4", tag="queue_append");
    graph_root +>:Flow:+> n1;
    n1 +>:Flow:+> n2;
    n2 +>:Flow:+> n3;
    n3 +>:Flow:+> n4;
    val = bfs_confidence(graph_root);
    assert val == 0.85;
}

test "find_snippet_by_id_hit" {
    graph_root = Snippet(cid="r", tag="root");
    target = Snippet(cid="t1", tag="leaf");
    graph_root +>:Flow:+> target;
    got = find_snippet_by_id(graph_root, "t1");
    assert got is not None;
    assert got.cid == "t1";
}

test "find_snippet_by_id_miss" {
    graph_root = Snippet(cid="r", tag="root");
    leaf = Snippet(cid="x", tag="leaf");
    graph_root +>:Flow:+> leaf;
    got = find_snippet_by_id(graph_root, "missing");
    assert got is None;
}

test "classify_pattern_bfs" {
    graph_root = Snippet(cid="r", tag="root");
    n1 = Snippet(cid="b1", tag="queue_init");
    n2 = Snippet(cid="b2", tag="while_queue");
    n3 = Snippet(cid="b3", tag="popleft");
    n4 = Snippet(cid="b4", tag="queue_append");
    graph_root +>:Flow:+> n1;
    n1 +>:Flow:+> n2;
    n2 +>:Flow:+> n3;
    n3 +>:Flow:+> n4;
    label = classify_pattern(graph_root);
    assert label == "BFS";
}

test "classify_pattern_dfs" {
    graph_root = Snippet(cid="r", tag="root");
    n1 = Snippet(cid="d1", tag="stack_init");
    n2 = Snippet(cid="d2", tag="while_stack");
    n3 = Snippet(cid="d3", tag="stack_pop");
    graph_root +>:Flow:+> n1;
    n1 +>:Flow:+> n2;
    n2 +>:Flow:+> n3;
    label = classify_pattern(graph_root);
    assert label == "DFS";
}

test "classify_pattern_dp" {
    graph_root = Snippet(cid="r", tag="root");
    n1 = Snippet(cid="p1", tag="recurse_self");
    n2 = Snippet(cid="p2", tag="memo");
    graph_root +>:Flow:+> n1;
    n1 +>:Flow:+> n2;
    label = classify_pattern(graph_root);
    assert label == "DP";
}
