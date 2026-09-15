"""CMB2/CMB2#543 — recursive groups inside groups."""

node Field {
    has fid: str;
    has ftype: str;
    has name: str = "";
    has desc: str = "";
}

edge Child {}

obj FieldStore {
    has graph_root: Field;
    has index: dict[str, Field] = {};

    def init() {
        self.graph_root = Field(fid="__root__", ftype="root", name="root");
        self.index["__root__"] = self.graph_root;
    }

    def link_child(self, parent: Field, child: Field) {
        parent +>:Child:+> child;
    }

    def register(self, node: Field) {
        self.index[node.fid] = node;
    }

    def lookup(self, fid: str) -> Field | None {
        if fid in self.index {
            return self.index[fid];
        }
        return None;
    }
}

walker CollectDescendantIds {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can walk with Field entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        if here.fid != self.origin {
            self.found.append(here.fid);
        }
        kids: list[Field] = [here ->:Child:->][?:Field];
        for kid in kids {
            visit kid;
        }
    }
}

def make_store -> FieldStore {
    return FieldStore();
}

def _spec_id(spec: dict) -> str {
    return spec["id"] as str;
}

def _spec_type(spec: dict) -> str {
    return spec["type"] as str;
}

def _spec_name(spec: dict) -> str {
    if "name" in spec {
        return spec["name"] as str;
    }
    return "";
}

def _spec_desc(spec: dict) -> str {
    if "desc" in spec {
        return spec["desc"] as str;
    }
    return "";
}

def add_field(store: FieldStore, spec: dict) -> str {
    fid: str = _spec_id(spec);
    if store.lookup(fid) {
        return fid;
    }
    node = Field(
        fid=fid,
        ftype=_spec_type(spec),
        name=_spec_name(spec),
        desc=_spec_desc(spec),
    );
    store.register(node);
    store.link_child(store.graph_root, node);
    return fid;
}

def resolve_group_id(group_ref: str | list) -> str {
    if group_ref is str {
        return group_ref;
    }
    parts: list = group_ref as list;
    if len(parts) < 2 {
        return parts[0] as str;
    }
    return parts[1] as str;
}

def add_group_field(store: FieldStore, group_ref: str | list, spec: dict) -> str | list {
    parent_id: str = resolve_group_id(group_ref);
    parent = store.lookup(parent_id);
    if not parent {
        return "";
    }
    fid: str = _spec_id(spec);
    ftype: str = _spec_type(spec);
    if store.lookup(fid) {
        if ftype == "group" {
            return [parent_id, fid];
        }
        return fid;
    }
    child = Field(
        fid=fid,
        ftype=ftype,
        name=_spec_name(spec),
        desc=_spec_desc(spec),
    );
    store.register(child);
    store.link_child(parent, child);
    if ftype == "group" {
        return [parent_id, fid];
    }
    return fid;
}

def list_descendant_ids(store: FieldStore, group_id: str) -> list[str] {
    origin = store.lookup(group_id);
    if not origin {
        return [];
    }
    w = origin spawn CollectDescendantIds(origin=group_id);
    ids: list[str] = w.found;
    ids.sort();
    return ids;
}

def field_exists(store: FieldStore, field_id: str) -> bool {
    node = store.lookup(field_id);
    if node {
        return True;
    }
    return False;
}

def group_child_count(store: FieldStore, group_id: str) -> int {
    parent = store.lookup(group_id);
    if not parent {
        return 0;
    }
    kids: list[Field] = [parent ->:Child:->][?:Field];
    return len(kids);
}

with entry {
    store = make_store();
    gid = add_field(
        store,
        {"id": "my_group_id", "desc": "Group", "type": "group"},
    );
    add_group_field(
        store,
        gid,
        {"id": "my_group_element_id", "name": "Group Element", "type": "text"},
    );
    sub_ref = add_group_field(
        store,
        gid,
        {"id": "my_subgroup_id", "desc": "Subgroup", "type": "group"},
    );
    add_group_field(
        store,
        sub_ref,
        {"id": "my_subgroup_element_id", "name": "Subgroup Element", "type": "text"},
    );
    print(list_descendant_ids(store, gid));
}

"""CMB2/CMB2#543 — recursive groups inside groups."""

node Field {
    has fid: str;
    has ftype: str;
    has name: str = "";
    has desc: str = "";
}

edge Child {}

obj FieldStore {
    has graph_root: Field;
    has index: dict[str, Field] = {};

    def init() {
        self.graph_root = Field(fid="__root__", ftype="root", name="root");
        self.index["__root__"] = self.graph_root;
    }

    def link_child(self, parent: Field, child: Field) {
        parent +>:Child:+> child;
    }

    def register(self, node: Field) {
        self.index[node.fid] = node;
    }

    def lookup(self, fid: str) -> Field | None {
        if fid in self.index {
            return self.index[fid];
        }
        return None;
    }
}

walker CollectDescendantIds {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can walk with Field entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        if here.fid != self.origin {
            self.found.append(here.fid);
        }
        kids: list[Field] = [here ->:Child:->][?:Field];
        for kid in kids {
            visit kid;
        }
    }
}

def make_store -> FieldStore {
    return FieldStore();
}

def _spec_id(spec: dict) -> str {
    return spec["id"] as str;
}

def _spec_type(spec: dict) -> str {
    return spec["type"] as str;
}

def _spec_name(spec: dict) -> str {
    if "name" in spec {
        return spec["name"] as str;
    }
    return "";
}

def _spec_desc(spec: dict) -> str {
    if "desc" in spec {
        return spec["desc"] as str;
    }
    return "";
}

def add_field(store: FieldStore, spec: dict) -> str {
    fid: str = _spec_id(spec);
    if store.lookup(fid) {
        return fid;
    }
    node = Field(
        fid=fid,
        ftype=_spec_type(spec),
        name=_spec_name(spec),
        desc=_spec_desc(spec),
    );
    store.register(node);
    store.link_child(store.graph_root, node);
    return fid;
}

def resolve_group_id(group_ref: str | list) -> str {
    if group_ref is str {
        return group_ref;
    }
    parts: list = group_ref as list;
    if len(parts) < 2 {
        return parts[0] as str;
    }
    return parts[1] as str;
}

def add_group_field(store: FieldStore, group_ref: str | list, spec: dict) -> str | list {
    parent_id: str = resolve_group_id(group_ref);
    parent = store.lookup(parent_id);
    if not parent {
        return "";
    }
    fid: str = _spec_id(spec);
    ftype: str = _spec_type(spec);
    if store.lookup(fid) {
        if ftype == "group" {
            return [parent_id, fid];
        }
        return fid;
    }
    child = Field(
        fid=fid,
        ftype=ftype,
        name=_spec_name(spec),
        desc=_spec_desc(spec),
    );
    store.register(child);
    store.link_child(parent, child);
    if ftype == "group" {
        return [parent_id, fid];
    }
    return fid;
}

def list_descendant_ids(store: FieldStore, group_id: str) -> list[str] {
    origin = store.lookup(group_id);
    if not origin {
        return [];
    }
    w = origin spawn CollectDescendantIds(origin=group_id);
    ids: list[str] = w.found;
    ids.sort();
    return ids;
}

def field_exists(store: FieldStore, field_id: str) -> bool {
    node = store.lookup(field_id);
    if node {
        return True;
    }
    return False;
}

def group_child_count(store: FieldStore, group_id: str) -> int {
    parent = store.lookup(group_id);
    if not parent {
        return 0;
    }
    kids: list[Field] = [parent ->:Child:->][?:Field];
    return len(kids);
}

with entry {
    store = make_store();
    gid = add_field(
        store,
        {"id": "my_group_id", "desc": "Group", "type": "group"},
    );
    add_group_field(
        store,
        gid,
        {"id": "my_group_element_id", "name": "Group Element", "type": "text"},
    );
    sub_ref = add_group_field(
        store,
        gid,
        {"id": "my_subgroup_id", "desc": "Subgroup", "type": "group"},
    );
    add_group_field(
        store,
        sub_ref,
        {"id": "my_subgroup_element_id", "name": "Subgroup Element", "type": "text"},
    );
    print(list_descendant_ids(store, gid));
}

test "add_field_links_under_root" {
    store = make_store();
    gid = add_field(store, {"id": "g1", "type": "group", "desc": "G"});
    assert gid == "g1";
    assert field_exists(store, "g1");
    assert group_child_count(store, "__root__") == 1;
}

test "nested_subgroup_returns_pair_ref" {
    store = make_store();
    gid = add_field(store, {"id": "g1", "type": "group"});
    sub_ref = add_group_field(store, gid, {"id": "sg1", "type": "group", "desc": "sub"});
    assert sub_ref == ["g1", "sg1"];
    assert group_child_count(store, "g1") == 1;
}

test "list_descendants_sorted_multilevel" {
    store = make_store();
    gid = add_field(store, {"id": "g1", "type": "group"});
    add_group_field(store, gid, {"id": "el1", "type": "text"});
    sub_ref = add_group_field(store, gid, {"id": "sg1", "type": "group"});
    add_group_field(store, sub_ref, {"id": "el2", "type": "text"});
    ds = list_descendant_ids(store, "g1");
    assert ds == ["el1", "el2", "sg1"];
}

test "unknown_parent_add_group_returns_empty" {
    store = make_store();
    r = add_group_field(store, "missing", {"id": "x", "type": "text"});
    assert r == "";
}

test "duplicate_add_field_idempotent" {
    store = make_store();
    a = add_field(store, {"id": "f1", "type": "text"});
    b = add_field(store, {"id": "f1", "type": "text"});
    assert a == b;
    assert group_child_count(store, "__root__") == 1;
}

test "resolve_group_id_pair_and_string" {
    assert resolve_group_id("g1") == "g1";
    assert resolve_group_id(["g1", "sg1"]) == "sg1";
}
