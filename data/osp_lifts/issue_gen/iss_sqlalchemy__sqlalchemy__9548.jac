"""sqlalchemy/sqlalchemy#9548 — wildcard relationship loader depth."""

glob WILDCARD_ONE = "*";
glob WILDCARD_RECURSIVE = "**";

node Entity {
    has cid: str;
    has kind: str;
}

edge Children {}
edge SubChildren {}
edge OtherRel {}

obj GraphHandle {
    has root_node: Entity = None;
    has index: dict[str, Entity] = {};
}

walker OneLevelCollect {
    has claimed: dict[str, bool] = {};
    has targets: list[str] = [];
    has origin: str = "";

    can step with Entity entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.origin {
            self.targets.append(here.cid);
        }
        kids: list[Entity] = [];
        for ch in [here ->:Children:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:SubChildren:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:OtherRel:->][?:Entity] {
            kids.append(ch);
        }
        if here.cid == self.origin {
            if kids {
                visit :0: kids;
            } else {
                disengage;
            }
        } else {
            disengage;
        }
    }
}

walker RecursiveCollect {
    has claimed: dict[str, bool] = {};
    has targets: list[str] = [];
    has origin: str = "";

    can step with Entity entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.origin {
            self.targets.append(here.cid);
        }
        kids: list[Entity] = [];
        for ch in [here ->:Children:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:SubChildren:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:OtherRel:->][?:Entity] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker CascadeCollect {
    has claimed: dict[str, bool] = {};
    has to_delete: list[str] = [];

    can step with Entity entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.to_delete.append(here.cid);
        kids: list[Entity] = [];
        for ch in [here ->:Children:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:SubChildren:->][?:Entity] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker Demo {
    can run with ` entry {
        gh = build_fixture();
        one = collect_loader_targets(gh, "p1", WILDCARD_ONE);
        rec = collect_loader_targets(gh, "p1", WILDCARD_RECURSIVE);
        print(f"demo one={one} recursive={rec}");
        disengage;
    }
}

def build_fixture -> GraphHandle {
    gh = GraphHandle();
    ot = Entity(cid="ot1", kind="other");
    p = Entity(cid="p1", kind="parent");
    c1 = Entity(cid="c1", kind="child");
    c2 = Entity(cid="c2", kind="child");
    sc = Entity(cid="sc1", kind="subchild");
    p +>:Children:+> c1;
    p +>:Children:+> c2;
    c1 +>:SubChildren:+> sc;
    p +>:OtherRel:+> ot;
    gh.root_node = p;
    gh.index["p1"] = p;
    gh.index["c1"] = c1;
    gh.index["c2"] = c2;
    gh.index["sc1"] = sc;
    gh.index["ot1"] = ot;
    return gh;
}

def build_diamond_fixture -> GraphHandle {
    gh = GraphHandle();
    d = Entity(cid="d", kind="parent");
    a = Entity(cid="a", kind="child");
    b = Entity(cid="b", kind="child");
    c = Entity(cid="c", kind="subchild");
    d +>:Children:+> b;
    d +>:Children:+> a;
    b +>:Children:+> c;
    a +>:Children:+> c;
    gh.root_node = d;
    gh.index["d"] = d;
    gh.index["a"] = a;
    gh.index["b"] = b;
    gh.index["c"] = c;
    return gh;
}

def collect_loader_targets(gh: GraphHandle, root_id: str, wildcard: str) -> list[str] {
    if root_id not in gh.index {
        return [];
    }
    if wildcard != WILDCARD_ONE and wildcard != WILDCARD_RECURSIVE {
        raise ValueError("unknown wildcard token");
    }
    ent = gh.index[root_id];
    if wildcard == WILDCARD_ONE {
        w = ent spawn OneLevelCollect(origin=root_id);
        xs = sorted(w.targets);
        print(f"collect_loader_targets {root_id} {wildcard} -> {xs}");
        return xs;
    }
    w = ent spawn RecursiveCollect(origin=root_id);
    xs = sorted(w.targets);
    print(f"collect_loader_targets {root_id} {wildcard} -> {xs}");
    return xs;
}

def cascade_delete_subtree(gh: GraphHandle, root_id: str) -> list[str] {
    if root_id not in gh.index {
        return [];
    }
    ent = gh.index[root_id];
    w = ent spawn CascadeCollect();
    ids = sorted(w.to_delete);
    for did in w.to_delete {
        if did not in gh.index {
            continue;
        }
        node = gh.index[did];
        chs: list[Entity] = [];
        for ch in [node ->:Children:->][?:Entity] {
            chs.append(ch);
        }
        for ch in chs {
            node del [->:Children:-> ch];
        }
        sub_chs: list[Entity] = [];
        for ch in [node ->:SubChildren:->][?:Entity] {
            sub_chs.append(ch);
        }
        for ch in sub_chs {
            node del [->:SubChildren:-> ch];
        }
        del gh.index[did];
    }
    print(f"cascade_delete_subtree {root_id} -> {ids}");
    return ids;
}

with entry {
    root spawn Demo;
}
