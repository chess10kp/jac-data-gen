# PROGRAM: iss_yukostan__Leetcode-Solutions__196.jac
# Lift of yukostan/Leetcode-Solutions#196 — Course Schedule (Leetcode 207).
# Kahn topological sort as an OSP walker; cycle <=> count < numCourses.

node Course {
    has cid: int;
    has indeg: int = 0;
    has visited: bool = False;
}

edge Seed;

walker Kahn {
    has claimed: dict[str, bool] = {};

    can seed with Root entry {
        visit :0: [here ->:Seed:->][?:Course];
    }

    can step with Course entry {
        key: str = here.cid as str;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        here.visited = True;
        for ch in [here ->:Seed:->][?:Course] {
            ch.indeg = ch.indeg - 1;
            if ch.indeg == 0 {
                visit ch;
            }
        }
    }
}

def build_courses(num_courses: int, prerequisites: list[list[int]]) -> dict[int, Course] {
    nodes: dict[int, Course] = {};
    for i in range(num_courses) {
        nodes[i] = Course(cid=i);
    }
    seen: dict[str, bool] = {};
    for p in prerequisites {
        ready: int = p[0];
        pre: int = p[1];
        # unknown-id tolerance: ignore out-of-range pairs like the issue's
        # bounded-matrix variant would with clamping
        if ready < 0 or ready >= num_courses or pre < 0 or pre >= num_courses {
            continue;
        }
        pk: str = (pre as str) + "->" + (ready as str);
        if pk in seen {
            continue;  # duplicate pairs must not inflate indegree
        }
        seen[pk] = True;
        # Seed edge doubles as the Prereq adjacency: pre -> ready, indeg on ready
        nodes[pre] +>:Seed:+> nodes[ready];
        nodes[ready].indeg = nodes[ready].indeg + 1;
    }
    return nodes;
}

def visited_count(nodes: dict[int, Course]) -> int {
    n: int = 0;
    for i in range(len(nodes)) {
        if nodes[i].visited {
            n = n + 1;
        }
    }
    return n;
}

def can_finish(num_courses: int, prerequisites: list[list[int]]) -> bool {
    if num_courses == 0 {
        return True;
    }
    nodes: dict[int, Course] = build_courses(num_courses, prerequisites);
    for i in range(num_courses) {
        if nodes[i].indeg == 0 {
            root +>:Seed:+> nodes[i];
        }
    }
    root spawn Kahn(claimed={});
    return visited_count(nodes) == num_courses;
}

test "no cycle linear chain" {
    assert can_finish(3, [[1, 0], [2, 1]]);
    assert can_finish(2, [[1, 0]]);
}

test "cycle detected" {
    assert not can_finish(2, [[0, 1], [1, 0]]);
    assert not can_finish(3, [[1, 0], [2, 1], [1, 2]]);
}

test "no prerequisites all free" {
    assert can_finish(4, []);
}

test "duplicate pairs ignored" {
    assert can_finish(2, [[1, 0], [1, 0]]);
}

test "out of range pairs tolerated" {
    assert can_finish(2, [[1, 0], [5, 1]]);
    assert not can_finish(2, [[1, 0], [1, 2], [2, 1]]);
}

test "zero courses trivially true" {
    assert can_finish(0, []);
}
