"""SaltyPatron/Laplace#1401 — forward-pass COUPLE: whole-observation tug across indexed planes."""

node Observation {
    has cid: str;
    has content: str;
    has scope: str = "";
}

node Plane {
    has cid: str;
    has plane_type: str;
    has force: int = 0;
}

node Entity {
    has cid: str;
    has label: str = "";
}

edge CoupleRoute {}
edge Contains {}

walker CoupleWalker {
    has claimed: dict[str, bool] = {};
    has responses: list[dict[str, any]] = {};
    has scope: str = "";
    has min_force: int = 0;

    can tug_obs with Observation entry {
        print ["couple", here.cid, self.scope];
        key = here.cid;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        planes: list[Plane] = [];
        for pl in [here ->:CoupleRoute:->][?:Plane] { planes.append(pl); }
        ents: list[Entity] = [];
        for ent in [here ->:Contains:->][?:Entity] { ents.append(ent); }
        if planes { visit :0: planes; }
        if ents { visit :0: ents; }
        if not planes and not ents { disengage; }
    }

    can tug_plane with Plane entry {
        print ["plane", here.cid, here.plane_type];
        key = here.cid;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        if here.force >= self.min_force {
            resp: dict[str, any] = {};
            resp["obs_route"] = "couple";
            resp["plane_id"] = here.cid;
            resp["plane_type"] = here.plane_type;
            resp["force"] = here.force;
            self.responses.append(resp);
        }
        planes: list[Plane] = [];
        for pl in [here ->:CoupleRoute:->][?:Plane] { planes.append(pl); }
        ents: list[Entity] = [];
        for ent in [here ->:Contains:->][?:Entity] { ents.append(ent); }
        if planes { visit :0: planes; }
        if ents { visit :0: ents; }
        if not planes and not ents { disengage; }
    }

    can tug_ent with Entity entry {
        print ["entity", here.cid];
        key = here.cid;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        planes: list[Plane] = [];
        for pl in [here ->:CoupleRoute:->][?:Plane] { planes.append(pl); }
        if planes { visit :0: planes; } else { disengage; }
    }
}

walker DemoWalker {
    can boot with Observation entry {
        print ["forward_pass", "couple", here.cid];
        wk = here spawn CoupleWalker(scope=here.scope, min_force=0);
        print ["responses", len(wk.responses)];
        disengage;
    }
}

def scope_min_force(scope: str) -> int {
    if scope == "high" { return 3; }
    return 0;
}

def sort_responses(items: list[dict[str, any]]) -> list[dict[str, any]] {
    ids: list[str] = [];
    for it in items { ids.append(it["plane_id"]); }
    ids = sorted(ids);
    out: list[dict[str, any]] = [];
    for pid in ids {
        for it in items {
            if it["plane_id"] == pid { out.append(it); break; }
        }
    }
    return out;
}

def resolve_observation(graph_root: Observation, obs_id: str) -> dict[str, str] | None {
    if graph_root.cid != obs_id { return None; }
    out: dict[str, str] = {};
    out["cid"] = graph_root.cid;
    out["content"] = graph_root.content;
    out["scope"] = graph_root.scope;
    return out;
}

def couple_observation(graph_root: Observation, obs_id: str, scope: str) -> list[dict[str, any]] {
    if graph_root.cid != obs_id { return []; }
    mf = scope_min_force(scope);
    wk = graph_root spawn CoupleWalker(scope=scope, min_force=mf);
    return sort_responses(wk.responses);
}

def forward_pass_couple(graph_root: Observation, obs_id: str, scope: str) -> list[dict[str, any]] {
    if resolve_observation(graph_root, obs_id) is None { return []; }
    return couple_observation(graph_root, obs_id, scope);
}

def build_couple_fixture -> Observation {
    o = Observation(cid="o1", content="whole-observation", scope="global");
    root ++> o;
    pa = Plane(cid="phys", plane_type="physicality", force=3);
    pb = Plane(cid="test", plane_type="testimony", force=5);
    shared = Entity(cid="ent", label="spider-colony");
    pc = Plane(cid="calc", plane_type="calculation", force=2);
    pd = Plane(cid="disc", plane_type="discourse", force=4);
    o +>:CoupleRoute:+> pb;
    o +>:CoupleRoute:+> pa;
    pb +>:Contains:+> shared;
    pa +>:Contains:+> shared;
    shared +>:CoupleRoute:+> pc;
    shared +>:CoupleRoute:+> pd;
    pc +>:CoupleRoute:+> pa;
    return o;
}

with entry {
    build_couple_fixture();
    root spawn DemoWalker;
}

test "resolve_hit" {
    o = build_couple_fixture();
    r = resolve_observation(o, "o1");
    assert r is not None;
    assert r["cid"] == "o1";
    assert r["content"] == "whole-observation";
    assert r["scope"] == "global";
}

test "resolve_miss" {
    o = build_couple_fixture();
    assert resolve_observation(o, "nope") is None;
}

test "forward_global_sorted" {
    o = build_couple_fixture();
    res = forward_pass_couple(o, "o1", "global");
    assert len(res) == 4;
    ids: list[str] = [];
    for it in res { ids.append(it["plane_id"]); }
    assert ids == ["calc", "disc", "phys", "test"];
}

test "forward_high_min_force" {
    o = build_couple_fixture();
    res = forward_pass_couple(o, "o1", "high");
    assert len(res) == 3;
    ids: list[str] = [];
    for it in res { ids.append(it["plane_id"]); }
    assert ids == ["disc", "phys", "test"];
}

test "forward_miss_obs" {
    o = build_couple_fixture();
    res = forward_pass_couple(o, "missing", "global");
    assert len(res) == 0;
}

test "couple_response_fields" {
    o = build_couple_fixture();
    res = couple_observation(o, "o1", "global");
    assert res[0]["obs_route"] == "couple";
    assert res[0]["plane_id"] == "calc";
    assert res[0]["plane_type"] == "calculation";
    assert res[0]["force"] == 2;
}
