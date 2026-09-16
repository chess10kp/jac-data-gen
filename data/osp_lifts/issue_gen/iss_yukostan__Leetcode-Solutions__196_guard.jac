"""yukostan/Leetcode-Solutions#196 — Leetcode 207 Course Schedule.

Idiomatic OSP lift: Course nodes connected by typed Prereq edges; Kahn
topological walk with claim-map + skip cycle policy (revisits are skipped,
never disengaged). Duplicate prerequisite pairs are deduplicated at build
time so indegrees count unique edges only. Public API mirrors the issue's
canFinish plus LC210-style find_order, with unknown-id tolerance (pairs
referencing out-of-range course ids are ignored).
"""
node Course {
    has cid: int;
    has indeg: int = 0;
}
edge Prereq;
node Hub;

# Build the directed graph pre -> ready; dedupe duplicate pairs, ignore unknown ids.
def build_graph(num_courses: int, prereqs: list[list[int]]) -> list[Course] {
    nodes: list[Course] = [];
    by_id: dict[int, Course] = {};
    for i in range(num_courses) {
        c = Course(cid=i);
        root ++> c;
        nodes.append(c);
        by_id[i] = c;
    }
    seen: dict[str, bool] = {};
    for p in prereqs {
        ready: int = p[0];
        pre: int = p[1];
        if pre in by_id {
            if ready in by_id {
                key: str = pre + "->" + ready;
                if key in seen {
                    continue;
                }
                seen[key] = True;
                by_id[pre] +>:Prereq:+> by_id[ready];
                by_id[ready].indeg += 1;
            }
        }
    }
    return nodes;
}

walker Kahn {
    has seeds: list[Course] = [];
    has claimed: dict[int, bool] = {};
    has order: list[int] = [];
    can start with Hub entry {
        visit :0: self.seeds;
    }
    can step with Course entry {
        # claim-map + skip: revisits (diamonds, duplicate edges) are skipped
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[Course] = [];
        for kid in [here ->:Prereq:->][?:Course] {
            kid.indeg -= 1;
            if kid.indeg <= 0 {
                kids.append(kid);
            }
        }
        if len(kids) > 0 {
            visit kids;
        }
    }
}

# Shared driver: returns the Kahn walker after the topological sweep.
def _run_topo(num_courses: int, prereqs: list[list[int]]) -> Kahn | None {
    nodes: list[Course] = build_graph(num_courses, prereqs);
    seeds: list[Course] = [];
    for c in nodes {
        if c.indeg == 0 {
            seeds.append(c);
        }
    }
    if len(seeds) == 0 {
        return None;
    }
    h = Hub();
    root ++> h;
    wk = h spawn Kahn(seeds=seeds, claimed={}, order=[]);
    return wk;
}

def can_finish(num_courses: int, prereqs: list[list[int]]) -> bool {
    if num_courses == 0 {
        return True;
    }
    wk = _run_topo(num_courses, prereqs);
    if wk == None {
        return False;
    }
    return len(wk.order) == num_courses;
}

def find_order(num_courses: int, prereqs: list[list[int]]) -> list[int] {
    if num_courses == 0 {
        return [];
    }
    wk = _run_topo(num_courses, prereqs);
    if wk == None {
        return [];
    }
    if len(wk.order) == num_courses {
        return wk.order;
    }
    return [];
}

test "no_cycle_linear" {
    order = find_order(3, [[1, 0], [2, 1]]);
    assert order == [0, 1, 2];
    assert can_finish(3, [[1, 0], [2, 1]]);
}

test "simple_cycle" {
    assert can_finish(2, [[0, 1], [1, 0]]) == False;
    assert find_order(2, [[0, 1], [1, 0]]) == [];
}

test "empty_courses" {
    assert can_finish(0, []);
    assert find_order(0, []) == [];
}

test "duplicate_pairs" {
    assert can_finish(2, [[1, 0], [1, 0], [1, 0]]);
    assert find_order(2, [[1, 0], [1, 0], [1, 0]]) == [0, 1];
}

test "diamond_dag" {
    prereqs = [[1, 0], [2, 0], [3, 1], [3, 2], [1, 0]];
    assert can_finish(4, prereqs);
    order = find_order(4, prereqs);
    assert sorted(order) == [0, 1, 2, 3];
    assert order[0] == 0;
    assert order[3] == 3;
}

test "unknown_ids_ignored" {
    assert can_finish(2, [[1, 0], [1, 5], [9, 0]]);
    order = find_order(2, [[1, 0], [1, 5], [9, 0]]);
    assert sorted(order) == [0, 1];
}
