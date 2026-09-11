"""Guard tests for iss_elizaOS__eliza__22896.jac"""

obj WorldPlatform { has entities: dict[str, Entity]; }
node Entity { has entity_id: str; has kind: str; has active: bool = True; }
edge Contains {}

walker CascadeCollect {
    has claimed: dict[str, bool];
    has found: list[Entity] = [];
    can step with Entity entry {
        if here.entity_id in self.claimed { skip; }
        self.claimed[here.entity_id] = True;
        self.found.append(here);
        visit [->:Contains:->];
    }
}

def _wire(entities: list[tuple[str, str]], contains: list[tuple[str, str]]) -> WorldPlatform {
    mp: dict[str, Entity] = {};
    for (eid, kind) in entities {
        if eid not in mp { e = Entity(entity_id=eid, kind=kind); root ++> e; mp[eid] = e; }
    }
    for (parent, child) in contains {
        p = mp.get(parent, None); c = mp.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    return WorldPlatform(entities=mp);
}

def _resolve(world: WorldPlatform, entity_id: str) -> Entity | None {
    return world.entities.get(entity_id, None);
}

def load_world(entities: list[tuple[str, str]], contains: list[tuple[str, str]]) -> WorldPlatform {
    return _wire(entities, contains);
}

def reset_entity(world: WorldPlatform, entity_id: str) -> list[str] {
    start = _resolve(world, entity_id);
    if start is None { return []; }
    w = start spawn CascadeCollect(claimed={});
    deactivated: list[str] = [];
    for ent in w.found {
        if ent.active { ent.active = False; deactivated.append(ent.entity_id); }
    }
    return sorted(deactivated);
}

def active_entities(world: WorldPlatform) -> list[str] {
    out: list[str] = [];
    for ent in world.entities.values() { if ent.active { out.append(ent.entity_id); } }
    return sorted(out);
}

test "cascade reset preserves parent" {
    w = load_world(
        [("world", "root"), ("scenario", "scenario"), ("agent", "agent"), ("tool", "tool")],
        [("world", "scenario"), ("scenario", "agent"), ("scenario", "tool")],
    );
    assert active_entities(w) == ["agent", "scenario", "tool", "world"];
    assert reset_entity(w, "scenario") == ["agent", "scenario", "tool"];
    assert active_entities(w) == ["world"];
}

test "diamond adversarial cascade" {
    w = load_world(
        [("root", "r"), ("left", "l"), ("right", "r"), ("base", "b")],
        [("root", "left"), ("root", "right"), ("left", "base"), ("right", "base")],
    );
    assert reset_entity(w, "root") == ["base", "left", "right", "root"];
    assert active_entities(w) == [];
}

test "unknown entity tolerant" {
    w = load_world([("only", "x")], []);
    assert reset_entity(w, "missing") == [];
    assert active_entities(w) == ["only"];
}

test "idempotent reset" {
    w = load_world([("a", "x"), ("b", "x")], [("a", "b")]);
    assert reset_entity(w, "a") == ["a", "b"];
    assert reset_entity(w, "a") == [];
    assert active_entities(w) == [];
}
