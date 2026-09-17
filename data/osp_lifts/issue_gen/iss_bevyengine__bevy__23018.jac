# bevyengine/bevy#23018 — Relational Queries (idiomatic OSP lift)
node Entity {
    has eid: int;
    has name: str;
    has comp: str = "";
    has value: int = 0;
    has changed: bool = False;
}

edge ChildOf {}

def make_entity(eid: int, name: str, comp: str, value: int) -> Entity {
    e = Entity(eid=eid, name=name, comp=comp, value=value);
    root ++> e;
    return e;
}

def parent_of(e: Entity) -> Entity | None {
    ps = [e ->:ChildOf:->][?:Entity];
    if len(ps) == 0 { return None; }
    return ps[0];
}

def parent_value(e: Entity) -> int | None {
    p = parent_of(e);
    if p is None { return None; }
    if p.comp == "" { return None; }
    return p.value;
}

def first_ancestor_value(e: Entity) -> int | None {
    cur = parent_of(e);
    while cur is not None {
        if cur.comp != "" { return cur.value; }
        cur = parent_of(cur);
    }
    return None;
}

def first_sibling_with(e: Entity) -> Entity | None {
    p = parent_of(e);
    if p is None { return None; }
    for sib in [p <-:ChildOf:<-][?:Entity] {
        if sib.eid != e.eid and sib.comp != "" { return sib; }
    }
    return None;
}

def first_descendant_with(e: Entity) -> Entity | None {
    found: Entity | None = None;
    for d in [e <-:ChildOf:<-][?:Entity] {
        if d.comp != "" {
            found = d;
            break;
        }
        sub = first_descendant_with(d);
        if sub is not None {
            found = sub;
            break;
        }
    }
    return found;
}

walker ChangeSweep {
    has claimed: dict[int, bool] = {};
    has any_changed: bool = False;

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.changed { self.any_changed = True; }
        kids: list[Entity] = [here <-:ChildOf:<-][?:Entity];
        visit kids;
    }
}

def any_child_changed(e: Entity) -> bool {
    wk = e spawn ChangeSweep(claimed={}, any_changed=False);
    return wk.any_changed;
}

def connect_child(parent: Entity, child: Entity) {
    child +>:ChildOf:+> parent;
}
