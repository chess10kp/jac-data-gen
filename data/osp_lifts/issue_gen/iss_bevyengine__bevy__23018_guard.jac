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

test "diamond_revisit_no_truncation" {
    a = make_entity(1, "a", "hp", 5);
    b = make_entity(2, "b", "", 0);
    c = make_entity(3, "c", "hp", 9);
    d = make_entity(4, "d", "", 0);
    connect_child(a, b);
    connect_child(a, c);
    connect_child(b, d);
    connect_child(c, d);
    # d reachable from both b and c: revisit must be skipped, not fatal
    assert any_child_changed(a) == False;
    assert first_descendant_with(a) is not None;
    # parent_value via diamond: d's parent is whichever connected first
    assert parent_value(d) is not None;
}

test "unknown_and_missing_relations_tolerated" {
    orphan = make_entity(10, "orphan", "hp", 3);
    assert parent_of(orphan) is None;
    assert parent_value(orphan) is None;
    assert first_ancestor_value(orphan) is None;
    assert first_sibling_with(orphan) is None;
    assert first_descendant_with(orphan) is None;
    assert any_child_changed(orphan) == False;
}

test "parent_and_ancestor_queries" {
    gp = make_entity(20, "gp", "hp", 1);
    mid = make_entity(21, "mid", "", 0);
    leaf = make_entity(22, "leaf", "", 0);
    connect_child(gp, mid);
    connect_child(mid, leaf);
    assert parent_value(leaf) is None;
    assert first_ancestor_value(leaf) == 1;
    assert parent_value(mid) == 1;
    assert first_ancestor_value(gp) is None;
}

test "first_descendant_depth_order" {
    r = make_entity(30, "r", "", 0);
    far = make_entity(32, "far", "item", 7);
    connect_child(r, far);
    hit = first_descendant_with(r);
    assert hit is not None;
    assert hit.value == 7;
    assert hit.eid == 32;
}

test "sibling_query" {
    p = make_entity(40, "p", "", 0);
    s1 = make_entity(41, "s1", "", 0);
    s2 = make_entity(42, "s2", "item", 3);
    s3 = make_entity(43, "s3", "item", 4);
    connect_child(p, s1);
    connect_child(p, s2);
    connect_child(p, s3);
    hit = first_sibling_with(s1);
    assert hit is not None;
    assert hit.eid == 42;
    assert first_sibling_with(s2) is not None;
}

test "changed_cascade_detects_deep_flag" {
    top = make_entity(50, "top", "", 0);
    m = make_entity(51, "m", "", 0);
    deep = make_entity(52, "deep", "hp", 2);
    deep.changed = True;
    connect_child(top, m);
    connect_child(m, deep);
    assert any_child_changed(top) == True;
    assert any_child_changed(m) == True;
    assert any_child_changed(deep) == True;
}
