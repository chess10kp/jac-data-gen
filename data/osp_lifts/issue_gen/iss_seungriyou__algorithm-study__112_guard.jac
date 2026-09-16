"""seungriyou/algorithm-study#112 — LC 210 Course Schedule II."""

node Course {
    has cid: int;
    has indeg: int = 0;
}

edge Requires {}

walker TracePing {
    has tag: str = "";

    can emit with Course entry {
        print("trace", self.tag);
        disengage;
    }
}

walker KahnWalker {
    has order: list[int] = [];
    has need: int = 0;
    has pending: list[Course] = [];
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can sort with Course entry {
        here spawn TracePing(tag="kahn");
        if not self.started {
            self.started = True;
            print("kahn boot", self.need);
            if len(self.pending) == 0 {
                disengage;
            }
            visit :0: self.pending;
            skip;
        }
        if here.indeg > 0 {
            skip;
        }
        cid_key = str(here.cid);
        if cid_key in self.claimed {
            skip;
        }
        self.claimed[cid_key] = True;
        self.order.append(here.cid);
        print("take", here.cid);
        nbrs: list[Course] = [here ->:Requires:->][?:Course];
        for nb in nbrs {
            nb.indeg -= 1;
            if nb.indeg == 0 {
                visit :0: [nb];
            }
        }
    }
}

def seed_zero_indeg(courses: list[Course]) -> list[Course] {
    pending: list[Course] = [];
    for c in courses {
        if c.indeg == 0 {
            pending.append(c);
        }
    }
    return pending;
}

def find_order(num_courses: int, prerequisites: list[list[int]]) -> list[int] {
    if num_courses <= 0 {
        return [];
    }
    courses: list[Course] = [];
    i: int = 0;
    while i < num_courses {
        c = Course(cid=i);
        root ++> c;
        courses.append(c);
        i += 1;
    }
    for pair in prerequisites {
        if len(pair) < 2 {
            continue;
        }
        dst = pair[0];
        src = pair[1];
        if src < 0 or src >= num_courses {
            continue;
        }
        if dst < 0 or dst >= num_courses {
            continue;
        }
        courses[src] +>:Requires:+> courses[dst];
        courses[dst].indeg += 1;
    }
    pending = seed_zero_indeg(courses);
    w = courses[0] spawn KahnWalker(
        order=[],
        need=num_courses,
        pending=pending,
        claimed={},
        started=False
    );
    if len(w.order) != num_courses {
        return [];
    }
    return w.order;
}

test "zero_courses" {
    assert (find_order(0, []) == []);;
}

test "single_course" {
    assert (find_order(1, []) == [0]);;
}

test "linear_chain" {
    assert (find_order(4, [[1, 0], [2, 1], [3, 2]]) == [0, 1, 2, 3]);;
}

test "cycle_returns_empty" {
    assert (find_order(2, [[0, 1], [1, 0]]) == []);;
}

test "diamond_topo" {
    assert (find_order(4, [[1, 0], [2, 0], [3, 1], [3, 2]]) == [0, 2, 1, 3]);;
}

test "disconnected_components" {
    assert (find_order(3, [[1, 0]]) == [0, 1, 2]);;
}
