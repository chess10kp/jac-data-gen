"""elizaOS/eliza#22896 — resettable synthetic-world test platform (OSP)."""

obj WorldPlatform {
    has entities: dict[str, Entity];
}

node Entity {
    has entity_id: str;
    has kind: str;
    has active: bool = True;
}

edge Contains {}

walker CascadeCollect {
    has claimed: dict[str, bool];
    has found: list[Entity] = [];

    can step with Entity entry {
        if here.entity_id in self.claimed {
            skip;
        }
        self.claimed[here.entity_id] = True;
        self.found.append(here);
        visit [->:Contains:->];
    }
}

def _wire(
    entities: list[tuple[str, str]],
    contains: list[tuple[str, str]],
) -> WorldPlatform {
    mp: dict[str, Entity] = {};
    for (eid, kind) in entities {
        if eid not in mp {
            e = Entity(entity_id=eid, kind=kind);
            root ++> e;
            mp[eid] = e;
        }
    }
    for (parent, child) in contains {
        p = mp.get(parent, None);
        c = mp.get(child, None);
        if p is not None and c is not None {
            p +>:Contains:+> c;
        }
    }
    return WorldPlatform(entities=mp);
}

def _resolve(world: WorldPlatform, entity_id: str) -> Entity | None {
    return world.entities.get(entity_id, None);
}

def load_world(
    entities: list[tuple[str, str]],
    contains: list[tuple[str, str]],
) -> WorldPlatform {
    return _wire(entities, contains);
}

def reset_entity(world: WorldPlatform, entity_id: str) -> list[str] {
    start = _resolve(world, entity_id);
    if start is None {
        return [];
    }
    w = start spawn CascadeCollect(claimed={});
    deactivated: list[str] = [];
    for ent in w.found {
        if ent.active {
            ent.active = False;
            deactivated.append(ent.entity_id);
        }
    }
    return sorted(deactivated);
}

def active_entities(world: WorldPlatform) -> list[str] {
    out: list[str] = [];
    for ent in world.entities.values() {
        if ent.active {
            out.append(ent.entity_id);
        }
    }
    return sorted(out);
}
