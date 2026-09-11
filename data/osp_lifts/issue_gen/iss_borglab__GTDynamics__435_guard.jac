"""borglab/GTDynamics#435 — candidate + hidden guards."""

obj KinematicPlan { has order: list[str] = []; }
node Joint { has name: str; has offset: float = 0.0; }
edge ParentLink {}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can step with Joint entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [->:ParentLink:->][?:Joint];
    }
}

def _wire(links: list[tuple[str, str, float]]) -> dict[str, Joint] {
    mp: dict[str, Joint] = {};
    for (child, par, off) in links {
        if child not in mp { c = Joint(name=child, offset=off); root ++> c; mp[child] = c; }
        if par not in mp { p = Joint(name=par, offset=0.0); root ++> p; mp[par] = p; }
        mp[par] +>:ParentLink:+> mp[child];
    }
    return mp;
}

def _root_joint(mp: dict[str, Joint]) -> Joint | None {
    for j in [-->][?:Joint] { if len([j <-:ParentLink:<-]) == 0 { return j; } }
    return None;
}

def compile_traversal(links: list[tuple[str, str, float]]) -> KinematicPlan {
    mp = _wire(links);
    r = _root_joint(mp);
    if r is None { return KinematicPlan(order=[]); }
    w = r spawn OrderWalker(claimed={}, order=[]);
    return KinematicPlan(order=w.order);
}

def traversal_order(plan: KinematicPlan) -> list[str] { return plan.order; }

def forward_positions(plan: KinematicPlan, angles: dict[str, float]) -> dict[str, float] {
    pos: dict[str, float] = {};
    for nm in plan.order {
        par: str | None = None;
        off = 0.0;
        for j in [-->][?:Joint] {
            if j.name == nm {
                off = j.offset;
                for p in [j <-:ParentLink:<-][?:Joint] { par = p.name; }
            }
        }
        base = pos[par] if par is not None else 0.0;
        pos[nm] = base + off + angles.get(nm, 0.0);
    }
    return pos;
}

def query_point_positions(
    plan: KinematicPlan,
    angles: dict[str, float],
    queries: list[tuple[str, str]],
) -> list[tuple[str, float]] {
    pos = forward_positions(plan, angles);
    out: list[tuple[str, float]] = [];
    for (label, joint) in queries { if joint in pos { out.append((label, pos[joint])); } }
    return sorted(out);
}

test "compiled order is deterministic BFS" {
    plan = compile_traversal([
        ("base", "world", 0.0), ("shoulder", "base", 1.0),
        ("elbow", "shoulder", 0.5), ("wrist", "elbow", 0.25),
    ]);
    assert traversal_order(plan) == ["world", "base", "shoulder", "elbow", "wrist"];
}

test "FK replay matches offsets and angles" {
    plan = compile_traversal([("b", "a", 1.0), ("c", "b", 2.0)]);
    pos = forward_positions(plan, {"b": 0.5, "c": -0.5});
    assert pos["c"] == 3.0;
}

test "branched tree order" {
    plan = compile_traversal([
        ("left", "root", 1.0), ("right", "root", 1.0), ("leaf", "left", 0.1),
    ]);
    assert traversal_order(plan) == ["root", "left", "right", "leaf"];
}

test "query points sorted by label" {
    plan = compile_traversal([("b", "a", 1.0)]);
    got = query_point_positions(plan, {"b": 0.5}, [("z", "b"), ("a", "a")]);
    assert got == [("a", 0.0), ("z", 1.5)];
}
