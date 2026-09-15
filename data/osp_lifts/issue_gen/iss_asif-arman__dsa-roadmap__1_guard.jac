"""Graph traversal algorithms for asif-arman/dsa-roadmap#1."""

node GNode {
    has cid: str;
}

edge GEdge {}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            kids.append(ch);
        }
        cids: list[str] = [];
        for k in kids {
            cids.append(k.cid);
        }
        cids = sorted(cids);
        visit_list: list[GNode] = [];
        for c in cids {
            if c not in self.claimed {
                for k in kids {
                    if k.cid == c {
                        visit_list.append(k);
                    }
                }
            }
        }
        if visit_list {
            visit visit_list;
        } else {
            disengage;
        }
        print("bfs", self.order);
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            kids.append(ch);
        }
        cids: list[str] = [];
        for k in kids {
            cids.append(k.cid);
        }
        cids = sorted(cids);
        rev: list[GNode] = [];
        idx = len(cids) - 1;
        while idx >= 0 {
            c = cids[idx];
            for k in kids {
                if k.cid == c {
                    rev.append(k);
                }
            }
            idx -= 1;
        }
        if rev {
            visit :0: rev;
        } else {
            disengage;
        }
        print("dfs", self.order);
    }
}

walker CompWalker {
    has claimed: dict[str, bool] = {};
    has comp: list[str] = [];

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.comp.append(here.cid);
        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            kids.append(ch);
        }
        cids: list[str] = [];
        for k in kids {
            cids.append(k.cid);
        }
        cids = sorted(cids);
        visit_list: list[GNode] = [];
        for c in cids {
            if c not in self.claimed {
                for k in kids {
                    if k.cid == c {
                        visit_list.append(k);
                    }
                }
            }
        }
        if visit_list {
            visit visit_list;
        } else {
            disengage;
        }
        print("comp", self.comp);
    }
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has found: bool = False;

    can step with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            kids.append(ch);
        }
        cids: list[str] = [];
        for k in kids {
            cids.append(k.cid);
        }
        cids = sorted(cids);
        next_visit: list[GNode] = [];
        for c in cids {
            for k in kids {
                if k.cid == c {
                    if k.cid in self.claimed {
                        par = "";
                        if here.cid in self.parent {
                            par = self.parent[here.cid];
                        }
                        if k.cid != par {
                            self.found = True;
                        }
                    } else {
                        self.parent[k.cid] = here.cid;
                        next_visit.append(k);
                    }
                }
            }
        }
        if next_visit {
            visit next_visit;
        } else {
            disengage;
        }
        print("cycle", self.found);
    }
}

def clear_graph {
    victims: list[GNode] = [];
    for nd in [root -->][?:GNode] {
        victims.append(nd);
    }
    for nd in victims {
        destroy nd;
    }
}

def find_node(target: str) -> GNode | None {
    for nd in [root -->][?:GNode] {
        if nd.cid == target {
            return nd;
        }
    }
    return None;
}

def make_graph(edges: list[list[str]]) {
    store: dict[str, GNode] = {};
    for pair in edges {
        a = pair[0];
        b = pair[1];
        if a not in store {
            nd = GNode(cid=a);
            root ++> nd;
            store[a] = nd;
        }
        if b not in store {
            nd = GNode(cid=b);
            root ++> nd;
            store[b] = nd;
        }
        na = store[a] as GNode;
        nb = store[b] as GNode;
        na +>:GEdge:+> nb;
        nb +>:GEdge:+> na;
    }
}

def bfs(start_id: str) -> list[str] {
    start = find_node(start_id);
    if start == None {
        return [];
    }
    w = start spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs(start_id: str) -> list[str] {
    start = find_node(start_id);
    if start == None {
        return [];
    }
    w = start spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}

def connected_components -> list[list[str]] {
    result: list[list[str]] = [];
    global_claimed: dict[str, bool] = {};
    seeds: list[str] = [];
    for nd in [root -->][?:GNode] {
        seeds.append(nd.cid);
    }
    seeds = sorted(seeds);
    for cid in seeds {
        if cid not in global_claimed {
            start = find_node(cid);
            if start != None {
                w = start spawn CompWalker(claimed={}, comp=[]);
                comp_sorted = sorted(w.comp);
                result.append(comp_sorted);
                for mem in w.comp {
                    global_claimed[mem] = True;
                }
            }
        }
    }
    return result;
}

def has_cycle -> bool {
    global_claimed: dict[str, bool] = {};
    seeds: list[str] = [];
    for nd in [root -->][?:GNode] {
        seeds.append(nd.cid);
    }
    seeds = sorted(seeds);
    for cid in seeds {
        if cid not in global_claimed {
            start = find_node(cid);
            if start != None {
                w = start spawn CycleWalker(claimed={}, parent={}, found=False);
                if w.found {
                    return True;
                }
                for key in w.claimed {
                    global_claimed[key] = True;
                }
            }
        }
    }
    return False;
}

test "bfs_unknown_start" {
    clear_graph();
    make_graph([["a", "b"]]);
    assert bfs("z") == [];
}

test "bfs_linear" {
    clear_graph();
    make_graph([["a", "b"], ["b", "c"]]);
    assert bfs("a") == ["a", "b", "c"];
}

test "dfs_diamond" {
    clear_graph();
    make_graph([["a", "b"], ["a", "c"], ["b", "d"], ["c", "d"]]);
    assert dfs("a") == ["a", "c", "d", "b"];
}

test "connected_components_split" {
    clear_graph();
    make_graph([["a", "b"], ["c", "d"]]);
    assert connected_components() == [["a", "b"], ["c", "d"]];
}

test "has_cycle_triangle" {
    clear_graph();
    make_graph([["a", "b"], ["b", "c"], ["c", "a"]]);
    assert has_cycle() == True;
}

test "has_cycle_tree" {
    clear_graph();
    make_graph([["a", "b"], ["b", "c"]]);
    assert has_cycle() == False;
}
