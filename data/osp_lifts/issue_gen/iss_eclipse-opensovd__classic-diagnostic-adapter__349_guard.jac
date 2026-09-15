"""eclipse-opensovd/classic-diagnostic-adapter#349 nested ComParam recursive parse."""

node SimpleParam {
    has key: str = "";
    has value: str = "";
}

node ComplexParam {
    has key: str = "";
}

edge Child {}

walker FlattenWalker {
    has claimed: dict[str, bool] = {};
    has paths: list[str] = [];
    has prefix: str = "";
    has int_map: dict[str, int] = {};

    can walk_complex with ComplexParam entry {
        if here.jid in self.claimed {
            skip;
        }
        self.claimed[here.jid] = True;
        saved: str = self.prefix;
        if len(here.key) > 0 {
            if len(self.prefix) > 0 {
                self.prefix = self.prefix + "." + here.key;
            } else {
                self.prefix = here.key;
            }
        }
        kids_s: list[SimpleParam] = [here ->:Child:->][?:SimpleParam];
        kids_c: list[ComplexParam] = [here ->:Child:->][?:ComplexParam];
        for s in kids_s {
            full: str = self.prefix;
            if len(s.key) > 0 {
                if len(full) > 0 {
                    full = full + "." + s.key;
                } else {
                    full = s.key;
                }
            }
            self.paths.append(full);
            n: int = parse_leaf_int(s.value);
            if n >= 0 {
                self.int_map[full] = n;
            }
            print(full + "=" + s.value);
        }
        for c in kids_c {
            visit :0: [c];
        }
        self.prefix = saved;
    }

    can walk_simple with SimpleParam entry {
        if here.jid in self.claimed {
            skip;
        }
        self.claimed[here.jid] = True;
        full: str = self.prefix;
        if len(here.key) > 0 {
            if len(full) > 0 {
                full = full + "." + here.key;
            } else {
                full = here.key;
            }
        }
        self.paths.append(full);
        n: int = parse_leaf_int(here.value);
        if n >= 0 {
            self.int_map[full] = n;
        }
        print(full + "=" + here.value);
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};

    can demo with ComplexParam entry {
        if here.jid in self.claimed {
            skip;
        }
        self.claimed[here.jid] = True;
        print("nested_comparam_demo");
        leaves: list[str] = flatten_leaves(here);
        print("leaf_count=" + str(len(leaves)));
        disengage;
    }
}

def is_mapping(val: object) -> bool {
    return isinstance(val, dict);
}

def parse_leaf_int(value: str) -> int {
    if len(value) == 0 {
        return -1;
    }
    i: int = 0;
    n: int = 0;
    while i < len(value) {
        ch: str = value[i];
        if ch < "0" or ch > "9" {
            return -1;
        }
        n = n * 10 + (ord(ch) - 48);
        i = i + 1;
    }
    return n;
}

def fill_complex(parent: ComplexParam, fields: dict[str, object]) {
    keys: list[str] = sorted(fields.keys());
    i: int = 0;
    while i < len(keys) {
        k: str = keys[i];
        v = fields[k];
        if is_mapping(v) {
            child_c = ComplexParam(key=k);
            parent +>:Child:+> child_c;
            fill_complex(child_c, v as dict[str, object]);
        } else {
            child_s = SimpleParam(key=k, value=str(v));
            parent +>:Child:+> child_s;
        }
        i = i + 1;
    }
}

def parse_from_complex(fields: dict[str, object]) -> ComplexParam {
    root_node = ComplexParam(key="");
    fill_complex(root_node, fields);
    return root_node;
}

def flatten_leaves(root_node: ComplexParam) -> list[str] {
    w = root_node spawn FlattenWalker(
        claimed={}, paths=[], prefix="", int_map={}
    );
    out: list[str] = sorted(w.paths);
    return out;
}

def map_nack_number_of_retries(root_node: ComplexParam) -> dict[str, int] {
    w = root_node spawn FlattenWalker(
        claimed={}, paths=[], prefix="", int_map={}
    );
    keys: list[str] = sorted(w.int_map.keys());
    out: dict[str, int] = {};
    for k in keys {
        out[k] = w.int_map[k];
    }
    return out;
}

def get_retry_count(
    root_node: ComplexParam, field_path: str, default: int
) -> int {
    m: dict[str, int] = map_nack_number_of_retries(root_node);
    if field_path in m {
        return m[field_path];
    }
    return default;
}

with entry {
    inner_map: dict[str, object] = {"tries": "1"};
    doip_map: dict[str, object] = {
        "nack_number_of_retries": "2", "inner": inner_map
    };
    payload: dict[str, object] = {"doip": doip_map};
    tree = parse_from_complex(payload);
    root ++> tree;
    tree spawn DemoWalker(claimed={});
}

test "flatten_sorted" {
    inner_map: dict[str, object] = {"tries": "1"};
    doip_map: dict[str, object] = {
        "nack_number_of_retries": "2", "inner": inner_map
    };
    fields: dict[str, object] = {"doip": doip_map};
    tree = parse_from_complex(fields);
    leaves = flatten_leaves(tree);
    assert leaves == ["doip.inner.tries", "doip.nack_number_of_retries"];
}

test "map_retries" {
    inner_map: dict[str, object] = {"tries": "1"};
    doip_map: dict[str, object] = {
        "nack_number_of_retries": "2", "inner": inner_map
    };
    fields: dict[str, object] = {"doip": doip_map};
    tree = parse_from_complex(fields);
    m = map_nack_number_of_retries(tree);
    assert m["doip.nack_number_of_retries"] == 2;
    assert m["doip.inner.tries"] == 1;
}

test "get_retry_hit" {
    doip_map: dict[str, object] = {"nack_number_of_retries": "2"};
    fields: dict[str, object] = {"doip": doip_map};
    tree = parse_from_complex(fields);
    assert get_retry_count(tree, "doip.nack_number_of_retries", 0) == 2;
}

test "get_retry_default" {
    doip_map: dict[str, object] = {"nack_number_of_retries": "2"};
    fields: dict[str, object] = {"doip": doip_map};
    tree = parse_from_complex(fields);
    assert get_retry_count(tree, "missing.path", 99) == 99;
}

test "parse_leaf_int" {
    assert parse_leaf_int("42") == 42;
    assert parse_leaf_int("") == -1;
    assert parse_leaf_int("abc") == -1;
}
