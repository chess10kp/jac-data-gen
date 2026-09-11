"""Ahaanv19/tcg_collect#46 — DS2 objective prerequisite reachability (OSP lift)."""

obj ObjectiveGraph {
    def link(prereq: str, `obj: str) -> None;
    def reachable_from(obj_id: str) -> list[str];
}

node Objective {
    has oid: str;
}

edge Prereq {}

walker ObjectiveReachWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        matches = [root-->][?:Objective, oid == self.origin];
        if matches {
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Objective entry {
        if here.oid in self.claimed {
            skip;
        }
        self.claimed[here.oid] = True;
        if here.oid != self.origin {
            self.hits.append(here.oid);
        }
        visit [->:Prereq:->];
    }
}

impl ObjectiveGraph.link(prereq: str, `obj: str) -> None {
    pre_list = [root-->][?:Objective, oid == prereq];
    if pre_list {
        pre = pre_list[0];
    } else {
        pre = root ++> Objective(oid=prereq);
    }
    obj_list = [root-->][?:Objective, oid == `obj];
    if obj_list {
        tgt = obj_list[0];
    } else {
        tgt = root ++> Objective(oid=`obj);
    }
    pre +>:Prereq:+> tgt;
}

impl ObjectiveGraph.reachable_from(obj_id: str) -> list[str] {
    w = root spawn ObjectiveReachWalker(origin=obj_id);
    return sorted(w.hits);
}
