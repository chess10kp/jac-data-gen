"""Guard tests for iss_Ahaanv19__tcg_collect__46.jac"""

obj ObjectiveGraph {
    def link(prereq: str, `obj: str) -> None;
    def reachable_from(obj_id: str) -> list[str];
}

node Objective { has oid: str; }
edge Prereq {}

walker ObjectiveReachWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        matches = [root-->][?:Objective, oid == self.origin];
        if matches { visit [matches[0]]; } else { disengage; }
    }

    can step with Objective entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        if here.oid != self.origin { self.hits.append(here.oid); }
        visit [->:Prereq:->];
    }
}

impl ObjectiveGraph.link(prereq: str, `obj: str) -> None {
    pre_list = [root-->][?:Objective, oid == prereq];
    pre = pre_list[0] if pre_list else root ++> Objective(oid=prereq);
    obj_list = [root-->][?:Objective, oid == `obj];
    tgt = obj_list[0] if obj_list else root ++> Objective(oid=`obj);
    pre +>:Prereq:+> tgt;
}

impl ObjectiveGraph.reachable_from(obj_id: str) -> list[str] {
    w = root spawn ObjectiveReachWalker(origin=obj_id);
    return sorted(w.hits);
}

test "linear prereq chain" {
    g = ObjectiveGraph();
    g.link("basics", "intermediate");
    g.link("intermediate", "advanced");
    assert g.reachable_from("basics") == ["advanced", "intermediate"];
    assert g.reachable_from("intermediate") == ["advanced"];
    assert g.reachable_from("advanced") == [];
    assert g.reachable_from("missing") == [];
}

test "diamond adversarial order" {
    g = ObjectiveGraph();
    g.link("left", "capstone");
    g.link("right", "capstone");
    g.link("hub", "left");
    g.link("hub", "right");
    assert g.reachable_from("hub") == ["capstone", "left", "right"];
}

test "cycle claim-map not disengage" {
    g = ObjectiveGraph();
    g.link("a", "b");
    g.link("b", "c");
    g.link("c", "a");
    g.link("b", "d");
    assert g.reachable_from("a") == ["b", "c", "d"];
}
