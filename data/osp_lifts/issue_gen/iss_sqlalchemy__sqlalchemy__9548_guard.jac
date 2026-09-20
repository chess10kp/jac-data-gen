"""sqlalchemy/sqlalchemy#9548 — wildcard loader one-level vs recursive depth."""

node Entity {
    has cid: str;
    has kind: str;
}

edge Children {}
edge SubChildren {}
edge OtherRef {}

walker SeedWalker {
    can boot with Entity entry {
        print("boot");
        disengage;
    }
}

walker FindWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has hit: Entity | None = None;

    can seek with Entity entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = here;
            print(here.cid);
            disengage;
        }
        kids: list[Entity] = [];
        for ch in [here ->:Children:->][?:Entity] { kids.append(ch); }
        for ch in [here ->:SubChildren:->][?:Entity] { kids.append(ch); }
        for ch in [here ->:OtherRef:->][?:Entity] { kids.append(ch); }
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has remaining: int;
    has found: list[str] = [];

    can walk with Entity entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        nxt: list[Entity] = [];
        if self.remaining != 0 {
            for ch in [here ->:Children:->][?:Entity] { nxt.append(ch); }
            for ch in [here ->:SubChildren:->][?:Entity] { nxt.append(ch); }
            for ch in [here ->:OtherRef:->][?:Entity] { nxt.append(ch); }
        }
        if nxt {
            if self.remaining > 0 { self.remaining = self.remaining - 1; }
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

def wildcard_token() -> str { return "*"; }

def recursive_wildcard_token() -> str { return "**"; }

def depth_limit_for_token(token: str) -> int {
    if token == "**" { return -1; }
    if token == "*" { return 1; }
    return 0;
}

def schema_relationships(kind: str) -> list[str] {
    out: list[str] = [];
    if kind == "Parent" {
        out.append("children");
        out.append("other_thing");
    } elif kind == "Child" {
        out.append("sub_children");
    }
    return out;
}

def find_entity(anchor: Entity, cid: str) -> Entity | None {
    w = anchor spawn FindWalker(target=cid);
    return w.hit;
}

def resolve_root_entity(cid: str) -> Entity | None {
    anchors: list[Entity] = [];
    for ch in [root ->>][?:Entity] { anchors.append(ch); }
    for anchor in anchors {
        hit = find_entity(anchor, cid);
        if hit is not None { return hit; }
    }
    return None;
}

def make_issue_fixture -> Entity {
    ot = Entity(cid="o1", kind="OtherThing");
    sc = Entity(cid="s1", kind="SubChild");
    c1 = Entity(cid="c1", kind="Child");
    c2 = Entity(cid="c2", kind="Child");
    p = Entity(cid="p1", kind="Parent");
    root ++> p;
    p +>:OtherRef:+> ot;
    p +>:Children:+> c1;
    p +>:Children:+> c2;
    c1 +>:SubChildren:+> sc;
    return p;
}

def make_diamond_fixture -> Entity {
    top = Entity(cid="top", kind="Parent");
    left = Entity(cid="left", kind="Child");
    right = Entity(cid="right", kind="Child");
    bottom = Entity(cid="bottom", kind="SubChild");
    root ++> top;
    top +>:Children:+> left;
    top +>:Children:+> right;
    left +>:Children:+> bottom;
    right +>:Children:+> bottom;
    left +>:SubChildren:+> right;
    return top;
}

def selectin_wildcard_load(root_cid: str, token: str) -> list[str] {
    start = resolve_root_entity(root_cid);
    if start is None { return []; }
    rem = depth_limit_for_token(token);
    w = start spawn ClosureWalker(remaining=rem);
    return sorted(w.found);
}

def lazy_wildcard_load(root_cid: str, token: str, propagate: bool = False) -> list[str] {
    start = resolve_root_entity(root_cid);
    if start is None { return []; }
    if not propagate {
        out: list[str] = [start.cid];
        for ch in [start ->:Children:->][?:Entity] { out.append(ch.cid); }
        for ch in [start ->:SubChildren:->][?:Entity] { out.append(ch.cid); }
        for ch in [start ->:OtherRef:->][?:Entity] { out.append(ch.cid); }
        return sorted(out);
    }
    rem = depth_limit_for_token(token);
    w = start spawn ClosureWalker(remaining=rem);
    return sorted(w.found);
}

test "wildcard_tokens" {
    assert wildcard_token() == "*";
    assert recursive_wildcard_token() == "**";
    assert depth_limit_for_token("*") == 1;
    assert depth_limit_for_token("**") == -1;
    assert depth_limit_for_token("children") == 0;
}

test "schema_relationships" {
    parent_rels = schema_relationships("Parent");
    assert parent_rels == ["children", "other_thing"];
    child_rels = schema_relationships("Child");
    assert child_rels == ["sub_children"];
    assert schema_relationships("OtherThing") == [];
}

test "selectin_one_level" {
    make_issue_fixture();
    got = selectin_wildcard_load("p1", "*");
    assert got == ["c1", "c2", "o1", "p1"];
}

test "selectin_recursive" {
    make_issue_fixture();
    got = selectin_wildcard_load("p1", "**");
    assert got == ["c1", "c2", "o1", "p1", "s1"];
}

test "lazy_non_propagate" {
    make_issue_fixture();
    got = lazy_wildcard_load("p1", "*", propagate=False);
    assert got == ["c1", "c2", "o1", "p1"];
}

test "diamond_recursive_closure" {
    make_diamond_fixture();
    got = selectin_wildcard_load("top", "**");
    assert got == ["bottom", "left", "right", "top"];
}
