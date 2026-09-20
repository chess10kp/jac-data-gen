"""yukostan/Leetcode-Solutions#196 — Leetcode #207 Course Schedule."""

node Course {
    has cid: int;
    has status: int = 0;
}

edge Requires {}

walker DfsProbe {
    has claimed: dict[str, bool] = {};
    has ok: bool = True;

    can step with Course entry {
        key = str(here.cid);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;

        if here.status == 2 {
            skip;
        }
        if here.status == 1 {
            self.ok = False;
            disengage;
        }
        here.status = 1;

        kids: list[Course] = [here ->:Requires:->][?:Course];
        for ch in kids {
            visit :0: [ch];
        }
        here.status = 2;
    }
}

def build_graph(num_courses: int, prerequisites: list[list[int]]) -> dict[str, Course] {
    nodes: dict[str, Course] = {};
    for i in range(num_courses) {
        nd = Course(cid=i);
        root ++> nd;
        nodes[str(i)] = nd;
    }
    for pair in prerequisites {
        if len(pair) < 2 {
            continue;
        }
        course_id = pair[0];
        prereq_id = pair[1];
        if prereq_id < 0 or prereq_id >= num_courses {
            continue;
        }
        if course_id < 0 or course_id >= num_courses {
            continue;
        }
        pre_node = nodes[str(prereq_id)];
        course_node = nodes[str(course_id)];
        pre_node +>:Requires:+> course_node;
    }
    return nodes;
}

def can_finish(num_courses: int, prerequisites: list[list[int]]) -> bool {
    if num_courses == 0 {
        return True;
    }
    if len(prerequisites) == 0 {
        return True;
    }
    nodes = build_graph(num_courses, prerequisites);
    for i in range(num_courses) {
        nd = nodes[str(i)];
        if nd.status == 0 {
            w = nd spawn DfsProbe(claimed={}, ok=True);
            print(w.ok);
            if not w.ok {
                return False;
            }
        }
    }
    return True;
}
