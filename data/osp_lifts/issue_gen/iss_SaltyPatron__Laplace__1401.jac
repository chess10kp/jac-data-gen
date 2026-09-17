node Entity {
    has eid: str;
    has kind: str;
}
node Occurrence {
    has oid: str;
    has pos: int = 0;
}
node CalcState {
    has cid: str;
    has value: int = 0;
}
edge CONTAINS {}
edge TUGS {}
edge ATTESTS {}
edge COMPUTES {}

walker Couple {
    has claimed: dict[str, bool] = {};
    has scope: list[str] = [];
    has resp: dict[str, list[str]] = {};

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.kind in self.scope {
            if here.eid not in self.resp { self.resp[here.eid] = []; }
            self.resp[here.eid].append("structure");
        }
        kids: list[Entity] = [];
        for e in [here ->:CONTAINS:->][?:Entity] { kids.append(e); }
        for e in [here ->:TUGS:->][?:Entity] { kids.append(e); }
        visit kids;
    }
    can step_occ with Occurrence entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        if "occurrence" in self.scope {
            if here.oid not in self.resp { self.resp[here.oid] = []; }
            self.resp[here.oid].append("occurrence");
        }
    }
    can step_calc with CalcState entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if "calc" in self.scope {
            if here.cid not in self.resp { self.resp[here.cid] = []; }
            self.resp[here.cid].append("calc");
        }
        for t in [here ->:COMPUTES:->][?:Entity] { visit [t]; }
    }
}

def couple_observation(root_entity: Entity, scope: list[str] | None = None) -> dict[str, list[str]] {
    if scope is None { scope = ["structure", "occurrence", "calc"]; }
    w = root_entity spawn Couple(claimed={}, scope=scope, resp={});
    return w.resp;
}

with entry {
    core = Entity(eid="core", kind="structure");
    root ++> core;
    fork = Entity(eid="fork", kind="structure");
    test = Entity(eid="test", kind="structure");
    bank = Entity(eid="bank", kind="structure");
    occ1 = Occurrence(oid="o1", pos=0);
    occ2 = Occurrence(oid="o2", pos=1);
    calc = CalcState(cid="tb1", value=42);
    core +>:CONTAINS:+> fork;
    core +>:CONTAINS:+> test;
    fork +>:TUGS:+> bank;
    test +>:TUGS:+> bank;
    core +>:CONTAINS:+> occ1;
    core +>:CONTAINS:+> occ2;
    calc +>:COMPUTES:+> bank;
    core +>:CONTAINS:+> calc;

    resp = couple_observation(core);
    print(sorted(resp.keys()));
    w2 = core spawn Couple(claimed={}, scope=["calc"], resp={});
    print(w2.resp);
}
