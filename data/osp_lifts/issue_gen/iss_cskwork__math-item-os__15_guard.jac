"""cskwork/math-item-os#15 — Prerequisite DAG traversal (recursive CTE prototype).

Hand-rolled parent/child adjacency, deque BFS, and frontier-stack walks
simulating recursive CTE ancestor/descendant queries with per-skill item counts.
"""

node Skill {
    has skill_id: str;
    has item_count: int = 0;
}

edge Requires: Skill --> Skill {}

obj PrerequisiteGraph {
    has skills: dict[str, bool] = {};
    has item_counts: dict[str, int] = {};
    has skill_nodes: dict[str, Skill] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 16;
    has depth: int = 0;
    has origin: str = "";

    can step with Skill entry {
        if here.skill_id in self.claimed { skip; }
        if here.skill_id != self.origin or self.depth > 0 {
            self.claimed[here.skill_id] = True;
            self.found.append(here.skill_id);
        }
        if self.depth >= self.max_depth { skip; }
        prereqs = [here ->:Requires:->][?:Skill];
        nms: list[str] = [];
        for n in prereqs { nms.append(n.skill_id); }
        for nm in sorted(nms) {
            for n in prereqs {
                if n.skill_id == nm {
                    n spawn AncestorWalk(
                        claimed=self.claimed,
                        found=self.found,
                        max_depth=self.max_depth,
                        depth=self.depth + 1,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has max_depth: int = 16;
    has depth: int = 0;
    has origin: str = "";

    can step with Skill entry {
        if here.skill_id in self.claimed { skip; }
        self.claimed[here.skill_id] = True;
        if here.skill_id != self.origin { self.reached.append(here.skill_id); }
        if self.depth >= self.max_depth { skip; }
        children = [here <-:Requires:<-][?:Skill];
        nms: list[str] = [];
        for n in children { nms.append(n.skill_id); }
        for nm in sorted(nms) {
            for n in children {
                if n.skill_id == nm {
                    n spawn DescendantWalk(
                        claimed=self.claimed,
                        reached=self.reached,
                        max_depth=self.max_depth,
                        depth=self.depth + 1,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

def load_prerequisite_graph(
    skills: list[tuple[str, int]],
    prerequisites: list[tuple[str, str]],
) -> PrerequisiteGraph {
    g = PrerequisiteGraph();
    for (skill_id, count) in skills {
        g.skills[skill_id] = True;
        g.item_counts[skill_id] = count;
        nd = Skill(skill_id=skill_id, item_count=count);
        root ++> nd;
        g.skill_nodes[skill_id] = nd;
    }
    for (dependent, prereq) in prerequisites {
        if dependent in g.skills and prereq in g.skills {
            dep = g.skill_nodes[dependent];
            pre = g.skill_nodes[prereq];
            dep +>:Requires:+> pre;
        }
    }
    return g;
}

def get_ancestors(
    g: PrerequisiteGraph,
    skill_id: str,
    *,
    max_depth: int = 16,
) -> list[str] {
    if skill_id not in g.skills or max_depth <= 0 { return []; }
    nd = g.skill_nodes.get(skill_id, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(
        claimed={}, found=[], max_depth=max_depth, depth=0, origin=skill_id
    );
    return sorted(w.found);
}

def get_descendants(
    g: PrerequisiteGraph,
    skill_id: str,
    *,
    max_depth: int = 16,
) -> list[str] {
    if skill_id not in g.skills or max_depth <= 0 { return []; }
    nd = g.skill_nodes.get(skill_id, None);
    if nd is None { return []; }
    w = nd spawn DescendantWalk(
        claimed={}, reached=[], max_depth=max_depth, depth=0, origin=skill_id
    );
    return sorted(w.reached);
}

def aggregate_item_counts(
    g: PrerequisiteGraph,
    skill_id: str,
    direction: str = "descendants",
) -> list[tuple[str, int]] {
    if skill_id not in g.skills { return []; }
    reach: list[str] = [];
    if direction == "ancestors" {
        reach = get_ancestors(g, skill_id);
    } elif direction == "descendants" {
        reach = get_descendants(g, skill_id);
    } else {
        return [];
    }
    out: list[tuple[str, int]] = [];
    for sid in reach { out.append((sid, g.item_counts[sid])); }
    return sorted(out);
}

test "diamond revisit ancestor and descendant closure" {
    g = load_prerequisite_graph(
        [("apex", 1), ("left", 2), ("right", 3), ("join", 4)],
        [("right", "apex"), ("join", "right"), ("left", "apex"), ("join", "left")],
    );
    assert get_ancestors(g, "join") == ["apex", "left", "right"];
    assert get_descendants(g, "apex") == ["join", "left", "right"];
    assert get_ancestors(g, "join", max_depth=1) == ["left", "right"];
    assert get_descendants(g, "apex", max_depth=1) == ["left", "right"];
}

test "unknown id tolerance" {
    g = load_prerequisite_graph([("only", 5)], []);
    assert get_ancestors(g, "missing") == [];
    assert get_descendants(g, "missing") == [];
    assert get_ancestors(g, "only", max_depth=0) == [];
    assert get_ancestors(g, "only", max_depth=-3) == [];
    assert get_descendants(g, "only", max_depth=0) == [];
    assert get_descendants(g, "only", max_depth=-1) == [];
    assert aggregate_item_counts(g, "missing", "ancestors") == [];
    assert aggregate_item_counts(g, "only", "lateral") == [];
}

test "cycle reach terminates without disengage" {
    g = load_prerequisite_graph(
        [("a", 1), ("b", 2), ("c", 3)],
        [("c", "a"), ("a", "b"), ("b", "c")],
    );
    assert get_ancestors(g, "a") == ["a", "b", "c"];
    assert get_descendants(g, "c") == ["a", "b"];
    assert aggregate_item_counts(g, "a", "ancestors") == [("a", 1), ("b", 2), ("c", 3)];
}

test "ignored prerequisite endpoints" {
    g = load_prerequisite_graph(
        [("leaf", 4), ("root", 9)],
        [("phantom", "root"), ("leaf", "ghost"), ("leaf", "root")],
    );
    assert get_ancestors(g, "leaf") == ["root"];
    assert get_descendants(g, "root") == ["leaf"];
    assert get_ancestors(g, "ghost") == [];
    assert get_descendants(g, "phantom") == [];
    assert aggregate_item_counts(g, "leaf", "ancestors") == [("root", 9)];
}

test "solo isolated skill and triple fan counts" {
    solo = load_prerequisite_graph([("solo", 9)], []);
    assert get_ancestors(solo, "solo") == [];
    assert get_descendants(solo, "solo") == [];
    assert aggregate_item_counts(solo, "solo", "descendants") == [];
    fan = load_prerequisite_graph(
        [("top", 1), ("left", 2), ("mid", 3), ("right", 4), ("bot", 5)],
        [
            ("bot", "right"),
            ("mid", "top"),
            ("bot", "mid"),
            ("right", "top"),
            ("bot", "left"),
            ("left", "top"),
        ],
    );
    assert get_ancestors(fan, "bot") == ["left", "mid", "right", "top"];
    assert get_descendants(fan, "top") == ["bot", "left", "mid", "right"];
    assert aggregate_item_counts(fan, "bot", "ancestors") == [
        ("left", 2),
        ("mid", 3),
        ("right", 4),
        ("top", 1),
    ];
}
