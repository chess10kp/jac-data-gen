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
