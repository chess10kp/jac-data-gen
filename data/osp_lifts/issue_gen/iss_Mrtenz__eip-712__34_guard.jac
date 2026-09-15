"""EIP-712 recursive type schema registry. Mrtenz/eip-712#34."""

node SchemaRoot {
    has sid: str;
}

node TypeNode {
    has name: str;
    has cid: str;
}

node FieldNode {
    has fname: str;
    has type_ref: str;
}

edge Defines {}
edge HasField {}
edge RefType {}

def next_schema_id -> str {
    n: int = 0;
    for sr in [root -->][?:SchemaRoot] {
        n = n + 1;
    }
    return "schema_" + str(n);
}

def get_schema_root(sid: str) -> SchemaRoot | None {
    for sr in [root -->][?:SchemaRoot] {
        if sr.sid == sid {
            return sr;
        }
    }
    return None;
}

def find_type_under(sr: SchemaRoot, type_name: str) -> TypeNode | None {
    for tn in [sr ->:Defines:+>][?:TypeNode] {
        if tn.name == type_name {
            return tn;
        }
    }
    return None;
}

def build_schema(types: dict) -> str {
    sid = next_schema_id();
    sr = SchemaRoot(sid=sid);
    root ++> sr;
    name_to_node: dict[str, TypeNode] = {};
    for tname in types {
        cid = "t:" + tname;
        tn = TypeNode(name=tname, cid=cid);
        sr +>:Defines:+> tn;
        name_to_node[tname] = tn;
    }
    for tname in types {
        tn = name_to_node[tname];
        fields = types[tname];
        for fld in fields {
            fname = fld["name"];
            type_ref = fld["type"];
            fn = FieldNode(fname=fname, type_ref=type_ref);
            tn +>:HasField:+> fn;
            if type_ref in name_to_node {
                ref_tn = name_to_node[type_ref];
                fn +>:RefType:+> ref_tn;
            }
        }
    }
    return sid;
}

walker DepCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_type with TypeNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.name);
        print(here.name);
        kids: list[object] = [];
        for fld in [here ->:HasField:->][?:FieldNode] {
            for ref_tn in [fld ->:RefType:->][?:TypeNode] {
                kids.append(ref_tn);
            }
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker RecCheck {
    has claimed: dict[str, bool] = {};
    has cyclic: bool = False;

    can step_type with TypeNode entry {
        if here.cid in self.claimed {
            self.cyclic = True;
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.name);
        kids: list[object] = [];
        for fld in [here ->:HasField:->][?:FieldNode] {
            for ref_tn in [fld ->:RefType:->][?:TypeNode] {
                kids.append(ref_tn);
            }
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def dependency_closure(sid: str, type_name: str) -> list[str] {
    sr = get_schema_root(sid);
    if sr is None {
        return [];
    }
    start = find_type_under(sr, type_name);
    if start is None {
        return [];
    }
    w = start spawn DepCollect(claimed={});
    return sorted(w.found);
}

def is_recursive(sid: str, type_name: str) -> bool {
    sr = get_schema_root(sid);
    if sr is None {
        return False;
    }
    start = find_type_under(sr, type_name);
    if start is None {
        return False;
    }
    w = start spawn RecCheck(claimed={});
    return w.cyclic;
}

def field_names(sid: str, type_name: str) -> list[str] {
    sr = get_schema_root(sid);
    if sr is None {
        return [];
    }
    tn = find_type_under(sr, type_name);
    if tn is None {
        return [];
    }
    names: list[str] = [];
    for fld in [tn ->:HasField:->][?:FieldNode] {
        names.append(fld.fname);
    }
    return sorted(names);
}

test "build_and_field_names" {
    types: dict = {};
    person_fields: list = [];
    person_fields.append({"name": "name", "type": "string"});
    person_fields.append({"name": "wallet", "type": "Address"});
    types["Person"] = person_fields;
    addr_fields: list = [];
    addr_fields.append({"name": "addr", "type": "string"});
    types["Address"] = addr_fields;
    sid = build_schema(types);
    assert (field_names(sid, "Person") == ["name", "wallet"]);
    assert (field_names(sid, "Address") == ["addr"]);
}

test "acyclic_dependency_closure" {
    types: dict = {};
    person_fields: list = [];
    person_fields.append({"name": "name", "type": "string"});
    person_fields.append({"name": "wallet", "type": "Address"});
    types["Person"] = person_fields;
    addr_fields: list = [];
    addr_fields.append({"name": "addr", "type": "string"});
    types["Address"] = addr_fields;
    sid = build_schema(types);
    assert (dependency_closure(sid, "Person") == ["Address", "Person"]);
    assert (dependency_closure(sid, "Address") == ["Address"]);
}

test "acyclic_not_recursive" {
    types: dict = {};
    person_fields: list = [];
    person_fields.append({"name": "name", "type": "string"});
    person_fields.append({"name": "wallet", "type": "Address"});
    types["Person"] = person_fields;
    addr_fields: list = [];
    addr_fields.append({"name": "addr", "type": "string"});
    types["Address"] = addr_fields;
    sid = build_schema(types);
    assert (is_recursive(sid, "Person") == False);
    assert (is_recursive(sid, "Address") == False);
}

test "self_recursive_detected" {
    types: dict = {};
    node_fields: list = [];
    node_fields.append({"name": "next", "type": "Node"});
    types["Node"] = node_fields;
    sid = build_schema(types);
    assert (is_recursive(sid, "Node") == True);
    assert (dependency_closure(sid, "Node") == ["Node"]);
}

test "cycle_recursive_detected" {
    types: dict = {};
    a_fields: list = [];
    a_fields.append({"name": "b", "type": "B"});
    types["A"] = a_fields;
    b_fields: list = [];
    b_fields.append({"name": "a", "type": "A"});
    types["B"] = b_fields;
    sid = build_schema(types);
    assert (is_recursive(sid, "A") == True);
    assert (is_recursive(sid, "B") == True);
}

test "unknown_ids_tolerant" {
    types: dict = {};
    empty_fields: list = [];
    types["Only"] = empty_fields;
    sid = build_schema(types);
    assert (dependency_closure("missing", "Only") == []);
    assert (is_recursive("missing", "Only") == False);
    assert (field_names("missing", "Only") == []);
    assert (dependency_closure(sid, "Missing") == []);
    assert (is_recursive(sid, "Missing") == False);
    assert (field_names(sid, "Missing") == []);
}
