# LibreCat/Catmandu#34 — recursive "..." path operator for nested field selection.

node DataRoot {
    has cid: str = "root";
}

node Field {
    has cid: str;
    has name: str;
    has value: str = "";
    has is_branch: bool = False;
}

edge Child {}

walker ValueCollectWalker {
    has target: str;
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk_root with DataRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        kids: list[Field] = [];
        for ch in [here ->:Child:->][?:Field] {
            kids.append(ch);
        }
        visit :0: kids;
        print(len(self.found));
    }

    can walk_field with Field entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.name == self.target and not here.is_branch {
            self.found.append(here.value);
        }
        kids: list[Field] = [];
        for ch in [here ->:Child:->][?:Field] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker PathCollectWalker {
    has target: str;
    has paths: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk_root with DataRoot entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        kids: list[Field] = [];
        for ch in [here ->:Child:->][?:Field] {
            kids.append(ch);
        }
        visit :0: kids;
        print(len(self.paths));
    }

    can walk_field with Field entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.name == self.target and not here.is_branch {
            self.paths.append(here.cid);
        }
        kids: list[Field] = [];
        for ch in [here ->:Child:->][?:Field] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_cid(parent_cid: str, name: str) -> str {
    return parent_cid + "/" + name;
}

def build_under(parent: object, data: dict[str, object], parent_cid: str) -> None {
    keys: list[str] = sorted(data.keys());
    for name in keys {
        val = data[name];
        cid = make_cid(parent_cid, name);
        nd = Field(name=name, cid=cid);
        if type(val) is dict {
            nd.is_branch = True;
            parent ++> nd;
            build_under(nd, val as dict[str, object], cid);
        } else {
            nd.value = str(val);
            parent ++> nd;
        }
    }
}

def cid_parts(cid: str) -> list[str] {
    raw = cid.split("/");
    parts: list[str] = [];
    for i in range(1, len(raw)) {
        parts.append(raw[i]);
    }
    return parts;
}

def get_by_cid(data: dict[str, object], cid: str) -> str {
    parts = cid_parts(cid);
    cur: dict[str, object] = data;
    for i in range(0, len(parts) - 1) {
        cur = cur[parts[i]] as dict[str, object];
    }
    return str(cur[parts[len(parts) - 1]]);
}

def set_by_cid(data: dict[str, object], cid: str, new_val: str) -> None {
    parts = cid_parts(cid);
    cur: dict[str, object] = data;
    for i in range(0, len(parts) - 1) {
        cur = cur[parts[i]] as dict[str, object];
    }
    cur[parts[len(parts) - 1]] = new_val;
}

def dict_copy(data: dict[str, object]) -> dict[str, object] {
    out: dict[str, object] = {};
    keys: list[str] = sorted(data.keys());
    for k in keys {
        v = data[k];
        if type(v) is dict {
            out[k] = dict_copy(v as dict[str, object]);
        } else {
            out[k] = v;
        }
    }
    return out;
}

def trim_string(s: str) -> str {
    return s.strip();
}

def parse_recursive_path(path: str) -> str {
    if len(path) < 4 {
        raise ValueError("expected recursive path");
    }
    if path[0:3] != "..." {
        raise ValueError("expected recursive path");
    }
    name = path[3:];
    if len(name) == 0 {
        raise ValueError("empty field name");
    }
    return name;
}

def collect_values(data: dict[str, object], field: str) -> list[str] {
    graph_root = DataRoot(cid="root");
    build_under(graph_root, data, "root");
    w = graph_root spawn ValueCollectWalker(target=field, claimed={});
    out: list[str] = sorted(w.found);
    print(out);
    return out;
}

def trim(data: dict[str, object], path: str) -> dict[str, object] {
    field_name = parse_recursive_path(path);
    graph_root = DataRoot(cid="root");
    build_under(graph_root, data, "root");
    w = graph_root spawn PathCollectWalker(target=field_name, claimed={});
    result = dict_copy(data);
    for cid in w.paths {
        old_val = get_by_cid(result, cid);
        set_by_cid(result, cid, trim_string(old_val));
    }
    return result;
}

test "trim_nested_foo" {
    data: dict[str, object] = {};
    data["foo"] = "  x ";
    inner: dict[str, object] = {};
    inner["foo"] = "  y ";
    data["bar"] = inner;
    got = trim(data, "...foo");
    assert str(got["foo"]) == "x";
    inner_got = got["bar"] as dict[str, object];
    assert str(inner_got["foo"]) == "y";;
}

test "diamond_revisit_collect_once" {
    graph_root = DataRoot(cid="root");
    bar = Field(name="bar", cid="root/bar", is_branch=True);
    leaf = Field(name="foo", cid="root/bar/foo", value="  a  ");
    graph_root +>:Child:+> bar;
    bar +>:Child:+> leaf;
    graph_root +>:Child:+> leaf;
    w = graph_root spawn ValueCollectWalker(target="foo", claimed={});
    assert len(w.found) == 1;
    assert w.found[0] == "  a  ";;
}

test "parse_rejects_non_recursive" {
    bad = False;
    try {
        parse_recursive_path("foo");
    } except ValueError {
        bad = True;
    }
    assert bad;;
}

test "unknown_field_collect_empty" {
    data: dict[str, object] = {};
    data["bar"] = "  z ";
    got = collect_values(data, "missing");
    assert got == [];;
}

test "trim_preserves_non_matching" {
    data: dict[str, object] = {};
    data["foo"] = "  x ";
    data["baz"] = "  keep  ";
    nested: dict[str, object] = {};
    nested["foo"] = "  y ";
    data["bar"] = nested;
    got = trim(data, "...foo");
    assert str(got["baz"]) == "  keep  ";
    vals = collect_values(got, "foo");
    assert vals == ["x", "y"];;
}
