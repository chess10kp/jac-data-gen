"""Guard: eugenemalaschuk-source/arch-linter-net#123."""

obj MilestoneGraph { has nodes: dict[str, Milestone] = {}; }
node Milestone { has mid: str; }
edge Blocks {}

walker ReachWalk {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    can step with Milestone entry {
        if here.mid == self.target { self.found = True; disengage; }
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        visit [->:Blocks:->][?:Milestone];
    }
}

def load_milestones(
    milestones: list[str],
    depends: list[tuple[str, str]],
) -> MilestoneGraph {
    g = MilestoneGraph();
    for mid in milestones {
        if mid not in g.nodes {
            nd = Milestone(mid=mid);
            root ++> nd;
            g.nodes[mid] = nd;
        }
    }
    for (blocker, dependent) in depends {
        b = g.nodes.get(blocker, None);
        d = g.nodes.get(dependent, None);
        if b is None or d is None { continue; }
        b +>:Blocks:+> d;
    }
    return g;
}

def is_reachable(g: MilestoneGraph, src: str, dst: str) -> bool {
    start = g.nodes.get(src, None);
    end = g.nodes.get(dst, None);
    if start is None or end is None { return False; }
    w = start spawn ReachWalk(claimed={}, target=dst, found=False);
    return w.found;
}

def execution_order(g: MilestoneGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for (mid, nd) in g.nodes.items() {
        indeg[mid] = len([nd <-:Blocks:<-][?:Milestone]);
    }
    ready = sorted([m for (m, d) in indeg.items() if d == 0]);
    out: list[str] = [];
    while ready {
        cur = ready.pop(0);
        out.append(cur);
        nd = g.nodes.get(cur, None);
        if nd is None { continue; }
        for dep in [nd ->:Blocks:->][?:Milestone] {
            indeg[dep.mid] -= 1;
            if indeg[dep.mid] == 0 { ready.append(dep.mid); }
        }
        ready = sorted(ready);
    }
    return out if len(out) == len(g.nodes) else [];
}

def pending_blockers(
    g: MilestoneGraph,
    milestone: str,
    shipped: set[str],
) -> list[str] {
    nd = g.nodes.get(milestone, None);
    if nd is None { return []; }
    pending: list[str] = [];
    for blk in [nd <-:Blocks:<-][?:Milestone] {
        if blk.mid not in shipped { pending.append(blk.mid); }
    }
    return sorted(pending);
}

test "linear milestone order" {
    g = load_milestones(
        ["v02", "v03", "v04", "v05"],
        [("v02", "v03"), ("v03", "v04"), ("v02", "v05")],
    );
    assert is_reachable(g, "v02", "v04") == True;
    assert execution_order(g) == ["v02", "v03", "v04", "v05"];
    assert pending_blockers(g, "v04", {"v02"}) == ["v03"];
}

test "diamond reach adversarial" {
    g = load_milestones(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert is_reachable(g, "hub", "leaf") == True;
    assert execution_order(g) == ["hub", "left", "right", "leaf"];
}

test "cycle yields empty order" {
    g = load_milestones(["a", "b"], [("a", "b"), ("b", "a")]);
    assert execution_order(g) == [];
}

test "unknown milestone tolerant" {
    g = load_milestones(["solo"], []);
    assert pending_blockers(g, "missing", set()) == [];
}
