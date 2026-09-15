"""Course Schedule — sudosf/leetcode#123.
Directed prerequisite graph; cycle probe via OSP walker + claim map.
"""

node Course {
    has cid: int;
}

edge Prereq {}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has indegree: dict[str, int] = {};
    has processed: int = 0;

    can step with Course entry {
        key: str = str(here.cid);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        self.processed = self.processed + 1;
        print("probe ", here.cid);
        nbrs: list[Course] = [here ->:Prereq:->][?:Course];
        for nxt in nbrs {
            nk: str = str(nxt.cid);
            cur: int = 0;
            if nk in self.indegree {
                cur = self.indegree[nk];
            }
            self.indegree[nk] = cur - 1;
            if self.indegree[nk] == 0 {
                visit :0: nxt;
            }
        }
    }
}

def build_courses(num_courses: int, prerequisites: list[list[int]]) -> list[Course] {
    by_id: dict[int, Course] = {};
    out: list[Course] = [];
    for i in range(num_courses) {
        nd = Course(cid=i);
        root ++> nd;
        by_id[i] = nd;
        out.append(nd);
    }
    for pair in prerequisites {
        a: int = pair[0];
        b: int = pair[1];
        src = by_id[b];
        dst = by_id[a];
        src +>:Prereq:+> dst;
    }
    return out;
}

def can_finish(num_courses: int, prerequisites: list[list[int]]) -> bool {
    nodes: list[Course] = build_courses(num_courses, prerequisites);
    indegree: dict[str, int] = {};
    for i in range(num_courses) {
        indegree[str(i)] = 0;
    }
    for pair in prerequisites {
        a: int = pair[0];
        ak: str = str(a);
        indegree[ak] = indegree[ak] + 1;
    }
    claimed: dict[str, bool] = {};
    processed: int = 0;
    for nd in nodes {
        key: str = str(nd.cid);
        if indegree[key] != 0 {
            continue;
        }
        if key in claimed {
            continue;
        }
        w = nd spawn CycleProbe(claimed=claimed, indegree=indegree, processed=processed);
        claimed = w.claimed;
        indegree = w.indegree;
        processed = w.processed;
    }
    return processed == num_courses;
}

test "no_prereqs_three_courses" {
    assert (can_finish(3, []) == True);
}

test "single_course" {
    assert (can_finish(1, []) == True);
}

test "simple_chain" {
    prereqs: list[list[int]] = [[1, 0]];
    assert (can_finish(2, prereqs) == True);
}

test "two_node_cycle" {
    prereqs: list[list[int]] = [[1, 0], [0, 1]];
    assert (can_finish(2, prereqs) == False);
}

test "four_course_dag" {
    prereqs: list[list[int]] = [[1, 0], [2, 0], [3, 1], [3, 2]];
    assert (can_finish(4, prereqs) == True);
}

test "cycle_plus_extra_component" {
    prereqs: list[list[int]] = [[1, 0], [0, 1], [3, 2]];
    assert (can_finish(4, prereqs) == False);
}
