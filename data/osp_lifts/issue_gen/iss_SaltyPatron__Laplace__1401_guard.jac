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

test "diamond_revisit_multiplicity" {
    core = Entity(eid="d1", kind="structure");
    root ++> core;
    a = Entity(eid="da", kind="structure");
    b = Entity(eid="db", kind="structure");
    shared = Entity(eid="ds", kind="structure");
    core +>:CONTAINS:+> a;
    core +>:CONTAINS:+> b;
    a +>:TUGS:+> shared;
    b +>:TUGS:+> shared;
    resp = couple_observation(core, scope=["structure"]);
    assert "ds" in resp.keys();
    assert resp["ds"] == ["structure"];
    assert sorted(resp.keys()) == ["d1", "da", "db", "ds"];
}

test "unknown_id_tolerance" {
    iso = Entity(eid="ghost", kind="structure");
    root ++> iso;
    resp = couple_observation(iso, scope=["structure"]);
    assert resp == {"ghost": ["structure"]};
    stranger = Entity(eid="stranger", kind="unlisted");
    root ++> stranger;
    resp2 = couple_observation(stranger, scope=["structure"]);
    assert resp2 == {};
}

test "empty_scope_no_response" {
    lone = Entity(eid="z", kind="structure");
    root ++> lone;
    resp = couple_observation(lone, scope=[]);
    assert resp == {};
}

test "calc_route_tugs_entity" {
    c = Entity(eid="rc", kind="structure");
    root ++> c;
    tb = CalcState(cid="rtb", value=7);
    c +>:CONTAINS:+> tb;
    tgt = Entity(eid="rtgt", kind="structure");
    tb +>:COMPUTES:+> tgt;
    resp = couple_observation(c, scope=["calc", "structure"]);
    assert sorted(resp.keys()) == ["rc", "rtgt", "rtb"];
    assert resp["rtb"] == ["calc"];
    assert resp["rtgt"] == ["structure"];
}

test "typed_routes_distinct" {
    h = Entity(eid="th", kind="structure");
    root ++> h;
    o = Occurrence(oid="to", pos=3);
    h +>:CONTAINS:+> o;
    resp = couple_observation(h, scope=["structure", "occurrence", "calc"]);
    assert resp["th"] == ["structure"];
    assert resp["to"] == ["occurrence"];
}
