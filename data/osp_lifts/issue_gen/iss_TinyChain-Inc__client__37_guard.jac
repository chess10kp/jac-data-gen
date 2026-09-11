"""Guard: TinyChain-Inc/client#37."""

obj OrmSchema {
    has classes: dict[str, str] = {};
    has members: dict[str, dict[str, str]] = {};
    has instances: dict[str, str] = {};
    has max_depth: int = 4;
}

node TcClass { has cid: str; has name: str; }
node Instance { has iid: str; has class_id: str; }
edge Extends {}
edge Relates {}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    can step with TcClass entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.chain.append(here.cid);
        visit [->:Extends:->] else { disengage; };
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with Instance entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.reached.append(here.iid);
        visit [->:Relates:->] else { disengage; };
    }
}

walker BoundedMutWalk {
    has schema: OrmSchema;
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has reached: list[str] = [];
    has limit: int = 0;
    can step with Instance entry {
        if here.iid in self.claimed { skip; }
        cur = self.depths.get(here.iid, 0);
        if cur > self.limit { skip; }
        self.claimed[here.iid] = True;
        if _instance_writable(self.schema, here.iid) {
            self.reached.append(here.iid);
        }
        for nxt in [here ->:Relates:->][?:Instance] {
            if nxt.iid not in self.depths {
                self.depths[nxt.iid] = cur + 1;
            }
        }
        visit [->:Relates:->] else { disengage; };
    }
}

def _find_class(cid: str) -> TcClass | None {
    for c in [-->][?:TcClass] { if c.cid == cid { return c; } }
    return None;
}

def _find_instance(iid: str) -> Instance | None {
    for n in [-->][?:Instance] { if n.iid == iid { return n; } }
    return None;
}

def _effective_members(g: OrmSchema, class_id: str) -> dict[str, str] {
    anchor = _find_class(class_id);
    if anchor is None { return {}; }
    w = anchor spawn LineageWalk(claimed={}, chain=[]);
    merged: dict[str, str] = {};
    for cid in reversed(w.chain) {
        spec = g.members.get(cid, {});
        for (fld, kind) in spec.items() {
            merged[fld] = kind;
        }
    }
    return merged;
}

def _instance_writable(g: OrmSchema, iid: str) -> bool {
    cid = g.instances.get(iid, "");
    if cid == "" { return False; }
    eff = _effective_members(g, cid);
    for (_, kind) in eff.items() {
        if kind == "writable" { return True; }
    }
    return False;
}

def load_schema(
    classes: list[tuple[str, str]],
    extends: list[tuple[str, str]],
    members: dict[str, dict[str, str]],
    instances: list[tuple[str, str]],
    relates: list[tuple[str, str]],
    max_depth: int = 4,
) -> OrmSchema {
    cmp: dict[str, TcClass] = {};
    imp: dict[str, Instance] = {};
    cls_map: dict[str, str] = {};
    for (cid, name) in classes {
        cls_node = TcClass(cid=cid, name=name);
        root ++> cls_node;
        cmp[cid] = cls_node;
        cls_map[cid] = name;
    }
    for (child, parent) in extends {
        c = cmp.get(child, None);
        p = cmp.get(parent, None);
        if c is not None and p is not None { c +>:Extends:+> p; }
    }
    inst_map: dict[str, str] = {};
    for (iid, class_id) in instances {
        inst_node = Instance(iid=iid, class_id=class_id);
        root ++> inst_node;
        imp[iid] = inst_node;
        inst_map[iid] = class_id;
    }
    for (src, tgt) in relates {
        a = imp.get(src, None);
        b = imp.get(tgt, None);
        if a is not None and b is not None { a +>:Relates:+> b; }
    }
    return OrmSchema(classes=cls_map, members=members, instances=inst_map, max_depth=max_depth);
}

def annotated_fields(g: OrmSchema, class_id: str) -> list[str] {
    if class_id not in g.classes { return []; }
    eff = _effective_members(g, class_id);
    out: list[str] = [];
    for (fld, kind) in eff.items() {
        if kind != "unsupported" { out.append(fld); }
    }
    return sorted(out);
}

def query_reach(g: OrmSchema, start: str) -> list[str] {
    if start not in g.instances { return []; }
    anchor = _find_instance(start);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def mutate_bounded(g: OrmSchema, root_id: str, depth: int) -> list[str] {
    if root_id not in g.instances { return []; }
    anchor = _find_instance(root_id);
    if anchor is None { return []; }
    w = anchor spawn BoundedMutWalk(
        schema=g,
        claimed={},
        depths={root_id: 0},
        reached=[],
        limit=depth,
    );
    return sorted(w.reached);
}

test "class-aware inheritance merges annotations" {
    g = load_schema(
        [("user", "User"), ("admin", "Admin"), ("report", "Report")],
        [("admin", "user")],
        {
            "user": {"name": "writable", "id": "readonly"},
            "admin": {"role": "writable"},
            "report": {"title": "derived", "secret": "unsupported"},
        },
        [("u1", "user"), ("a1", "admin"), ("ro1", "report")],
        [("u1", "a1")],
    );
    assert annotated_fields(g, "admin") == ["id", "name", "role"];
    assert annotated_fields(g, "report") == ["title"];
}

test "bounded mutation respects writable surface and depth" {
    g = load_schema(
        [("user", "User")],
        [],
        {"user": {"name": "writable"}},
        [("u1", "user"), ("a1", "user"), ("ro1", "report")],
        [("u1", "a1")],
        {"user": {"name": "writable"}, "report": {"title": "derived"}},
        [("u1", "user"), ("a1", "user"), ("ro1", "report")],
        [("u1", "a1")],
    );
    assert mutate_bounded(g, "u1", 0) == ["u1"];
    assert mutate_bounded(g, "u1", 1) == ["a1", "u1"];
    assert mutate_bounded(g, "ro1", 0) == [];
}

test "diamond adversarial relationship reach" {
    g = load_schema(
        [("user", "User")],
        [],
        {"user": {"name": "writable"}},
        [("hub", "user"), ("left", "user"), ("right", "user"), ("cap", "user")],
        [("hub", "left"), ("hub", "right"), ("left", "cap"), ("right", "cap")],
    );
    assert query_reach(g, "hub") == ["cap", "hub", "left", "right"];
    assert mutate_bounded(g, "hub", 1) == ["hub", "left", "right"];
}

test "cyclic relates terminates once" {
    g = load_schema(
        [("user", "User")],
        [],
        {"user": {"name": "writable"}},
        [("a", "user"), ("b", "user"), ("c", "user")],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert query_reach(g, "a") == ["a", "b", "c"];
}

test "unknown ids tolerant" {
    g = load_schema([("user", "User")], [], {"user": {"name": "writable"}}, [("u1", "user")], []);
    assert annotated_fields(g, "missing") == [];
    assert query_reach(g, "missing") == [];
    assert mutate_bounded(g, "missing", 1) == [];
}
