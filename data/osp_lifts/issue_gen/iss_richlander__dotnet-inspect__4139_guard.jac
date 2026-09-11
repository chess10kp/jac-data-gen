"""Guard: richlander/dotnet-inspect#4139."""

node Member { has mid: str; }
edge Calls {}

obj CallGraph {
    has members: dict[str, Member] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Member entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.reached.append(here.mid);
        visit [->:Calls:->][?:Member];
    }
}

def load_call_graph(members: list[str], edges: list[tuple[str, str]]) -> CallGraph {
    cg = CallGraph();
    for mid in members {
        nd = Member(mid=mid);
        root ++> nd;
        cg.members[mid] = nd;
    }
    for (caller, callee) in edges {
        c = cg.members.get(caller, None);
        d = cg.members.get(callee, None);
        if c is not None and d is not None { c +>:Calls:+> d; }
    }
    return cg;
}

def reachable_members(graph: CallGraph, seed: str) -> list[str] {
    nd = graph.members.get(seed, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def callers_of(graph: CallGraph, member: str) -> list[str] {
    tgt = graph.members.get(member, None);
    if tgt is None { return []; }
    out: list[str] = [];
    for (mid, nd) in graph.members.items() {
        for callee in [nd ->:Calls:->][?:Member] {
            if callee.mid == member { out.append(mid); }
        }
    }
    return sorted(out);
}

test "call graph reachability" {
    cg = load_call_graph(
        ["Main", "Helper", "Util", "Leaf"],
        [("Main", "Helper"), ("Helper", "Util"), ("Main", "Leaf")],
    );
    assert reachable_members(cg, "Main") == ["Helper", "Leaf", "Main", "Util"];
    assert callers_of(cg, "Util") == ["Helper"];
}

test "diamond adversarial revisit" {
    cg = load_call_graph(
        ["hub", "left", "right", "bot"],
        [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
    );
    assert reachable_members(cg, "hub") == ["bot", "hub", "left", "right"];
}

test "missing seed returns empty" {
    cg = load_call_graph(["solo"], []);
    assert reachable_members(cg, "missing") == [];
}
