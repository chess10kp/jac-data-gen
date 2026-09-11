"""Guard: mistersilver-uk/fabricate#1070."""

obj CraftGraph { has parts: dict[str, Component] = {}; }

node Component {
    has cid: str;
    has kind: str;
}

edge Requires {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        for req in [here ->:Requires:->][?:Component] {
            visit [req];
        }
    }
}

walker DependentCollect {
    has seed: str = "";
    has claimed: dict[str, bool] = {};
    has doomed: list[str] = [];

    can seed_with with Root entry {
        for c in [-->][?:Component] {
            if c.cid == self.seed {
                visit [c];
            }
        }
    }

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.doomed.append(here.cid);
        for user in [here <-:Requires:<-][?:Component] {
            visit [user];
        }
    }
}

def load_craft_graph(
    components: list[tuple[str, str]],
    requires: list[tuple[str, str]],
) -> CraftGraph {
    g = CraftGraph();
    for (cid, kind) in components {
        if cid not in g.parts {
            c = Component(cid=cid, kind=kind);
            root ++> c;
            g.parts[cid] = c;
        }
    }
    for (src, dep) in requires {
        a = g.parts.get(src, None);
        b = g.parts.get(dep, None);
        if a is not None and b is not None { a +>:Requires:+> b; }
    }
    return g;
}

def reachable_components(g: CraftGraph, start: str) -> list[str] {
    anchor = g.parts.get(start, None);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def components_by_kind(g: CraftGraph, start: str, kind: str) -> list[str] {
    return sorted([c for c in reachable_components(g, start) if g.parts[c].kind == kind]);
}

def invalidate_component(g: CraftGraph, cid: str) -> list[str] {
    if cid not in g.parts { return []; }
    w = root spawn DependentCollect(seed=cid, claimed={}, doomed=[]);
    removed = sorted(set(w.doomed));
    for rid in removed {
        part_nd: Component | None = g.parts.get(rid, None);
        if part_nd is not None {
            for dep in [part_nd ->:Requires:->][?:Component] {
                part_nd del ->:Requires:-> dep;
            }
            for user in [part_nd <-:Requires:<-][?:Component] {
                user del ->:Requires:-> part_nd;
            }
            del part_nd;
            g.parts.pop(rid, None);
        }
    }
    return removed;
}

test "reverse-requirement reachability from crafted item" {
    g = load_craft_graph(
        [("steel", "mat"), ("gear", "part"), ("engine", "item")],
        [("engine", "gear"), ("gear", "steel")],
    );
    assert reachable_components(g, "engine") == ["engine", "gear", "steel"];
    assert components_by_kind(g, "engine", "mat") == ["steel"];
}

test "diamond revisit does not truncate closure" {
    g = load_craft_graph(
        [("hub", "item"), ("left", "part"), ("right", "part"), ("core", "mat")],
        [("hub", "left"), ("hub", "right"), ("left", "core"), ("right", "core")],
    );
    assert reachable_components(g, "hub") == ["core", "hub", "left", "right"];
}

test "invalidate cascades to dependents" {
    g = load_craft_graph(
        [("steel", "mat"), ("gear", "part"), ("engine", "item"), ("frame", "part")],
        [("engine", "gear"), ("gear", "steel"), ("frame", "steel")],
    );
    assert invalidate_component(g, "steel") == ["engine", "frame", "gear", "steel"];
    assert reachable_components(g, "engine") == [];
}
