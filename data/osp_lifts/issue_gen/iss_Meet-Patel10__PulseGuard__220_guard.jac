"""Meet-Patel10/PulseGuard#220 — topological sort + cycle detection learning paths."""

node Skill {
    has sid: str;
}

edge Requires {}

node GraphHandle {
    has nodes: dict[str, Skill] = {};
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has needed: list[str] = [];

    can climb with Skill entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.needed.append(here.sid);
        print("ancestor ", here.sid);
        parents: list[Skill] = [here <-:Requires:<-][?:Skill];
        visit parents else {
            disengage;
        }
    }
}

def add_skill(gh: GraphHandle, sid: str) -> Skill {
    if sid in gh.nodes {
        return gh.nodes[sid];
    }
    nd = Skill(sid=sid);
    root ++> nd;
    gh.nodes[sid] = nd;
    return nd;
}

def wire_prereqs(gh: GraphHandle, prerequisites: dict[str, list[str]]) {
    for skill_id in prerequisites {
        skill_nd = add_skill(gh, skill_id);
        prereq_list = prerequisites[skill_id];
        for prereq_id in prereq_list {
            prereq_nd = add_skill(gh, prereq_id);
            prereq_nd +>:Requires:+> skill_nd;
        }
    }
}

def collect_closure(gh: GraphHandle, missing: list[str]) -> list[str] {
    merged: list[str] = [];
    merged_set: dict[str, bool] = {};
    for mid in missing {
        nd = add_skill(gh, mid);
        w = nd spawn AncestorWalker(claimed={});
        for sid in w.needed {
            if sid not in merged_set {
                merged_set[sid] = True;
                merged.append(sid);
            }
        }
    }
    return merged;
}

def kahn_topo(gh: GraphHandle, node_ids: list[str]) -> list[str] | None {
    needed_set: dict[str, bool] = {};
    for nid in node_ids {
        needed_set[nid] = True;
    }
    indeg: dict[str, int] = {};
    for nid in node_ids {
        indeg[nid] = 0;
    }
    for nid in node_ids {
        nd = gh.nodes[nid];
        kids: list[Skill] = [nd ->:Requires:->][?:Skill];
        for kid in kids {
            if kid.sid in needed_set {
                indeg[kid.sid] += 1;
            }
        }
    }
    queue: list[str] = [];
    for nid in sorted(node_ids) {
        if indeg[nid] == 0 {
            queue.append(nid);
        }
    }
    result: list[str] = [];
    while len(queue) > 0 {
        cur = queue[0];
        rest: list[str] = [];
        idx = 1;
        while idx < len(queue) {
            rest.append(queue[idx]);
            idx += 1;
        }
        queue = rest;
        result.append(cur);
        cur_nd = gh.nodes[cur];
        out_kids: list[Skill] = [cur_nd ->:Requires:->][?:Skill];
        for kid in out_kids {
            if kid.sid in needed_set {
                indeg[kid.sid] -= 1;
                if indeg[kid.sid] == 0 {
                    queue.append(kid.sid);
                    queue = sorted(queue);
                }
            }
        }
    }
    if len(result) != len(node_ids) {
        return None;
    }
    return result;
}

def can_complete(missing: list[str], prerequisites: dict[str, list[str]]) -> bool {
    order = learning_path(missing, prerequisites);
    return order is not None;
}

def learning_path(missing: list[str], prerequisites: dict[str, list[str]]) -> list[str] | None {
    if len(missing) == 0 {
        return [];
    }
    gh = GraphHandle();
    root ++> gh;
    wire_prereqs(gh, prerequisites);
    for mid in missing {
        add_skill(gh, mid);
    }
    closure = collect_closure(gh, missing);
    order = kahn_topo(gh, closure);
    return order;
}

test "empty_missing" {
    order = learning_path([], {});
    assert order == [];
}

test "linear_chain" {
    prereqs: dict = {};
    prereqs["c"] = ["b"];
    prereqs["b"] = ["a"];
    order = learning_path(["c"], prereqs);
    assert order == ["a", "b", "c"];
}

test "diamond_topo" {
    prereqs: dict = {};
    prereqs["d"] = ["b", "c"];
    prereqs["b"] = ["a"];
    prereqs["c"] = ["a"];
    order = learning_path(["d"], prereqs);
    assert order == ["a", "b", "c", "d"];
}

test "cycle_none" {
    prereqs: dict = {};
    prereqs["a"] = ["b"];
    prereqs["b"] = ["a"];
    order = learning_path(["a"], prereqs);
    assert order is None;
}

test "can_complete_true" {
    prereqs: dict = {};
    prereqs["y"] = ["x"];
    ok = can_complete(["y"], prereqs);
    assert ok == True;
}

test "can_complete_false" {
    prereqs: dict = {};
    prereqs["p"] = ["q"];
    prereqs["q"] = ["p"];
    ok = can_complete(["p"], prereqs);
    assert ok == False;
}
