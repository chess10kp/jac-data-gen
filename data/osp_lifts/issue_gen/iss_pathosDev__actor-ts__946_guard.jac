"""Guard: pathosDev/actor-ts#946."""

obj RefStore {
    has objects: dict[str, RefObject] = {};
    has actor_refs: dict[str, str] = {};
}

node RefObject { has oid: str; has payload: dict[str, any] = {}; }

def load_ref_store(
    objects: list[tuple[str, dict]],
    actor_refs: list[tuple[str, str]] | None = None,
) -> RefStore {
    store = RefStore();
    for (oid, payload) in objects {
        if oid not in store.objects {
            nd = RefObject(oid=oid, payload=dict(payload));
            root ++> nd;
            store.objects[oid] = nd;
        }
    }
    for (name, target) in actor_refs or [] {
        store.actor_refs[name] = target;
    }
    return store;
}

def _encode_value(store: RefStore, value: object, path: dict[str, bool]) -> object {
    if value is None or isinstance(value, (int, float, bool)) { return value; }
    if isinstance(value, str) {
        if value.startswith("@actor:") { return value; }
        if value in store.actor_refs { return f"@actor:{store.actor_refs[value]}"; }
        if value.startswith("@obj:") {
            oid = value[5:];
            ref_obj = store.objects.get(oid, None);
            if ref_obj is None { return value; }
            if oid in path { return None; }
            path[oid] = True;
            encoded: dict[str, any] = {};
            for (k, v) in sorted(ref_obj.payload.items()) {
                encoded[k] = _encode_value(store, v, path);
            }
            del path[oid];
            return encoded;
        }
        return value;
    }
    if isinstance(value, list) {
        return [_encode_value(store, v, path) for v in value];
    }
    if isinstance(value, dict) {
        out: dict[str, any] = {};
        for (k, v) in sorted(value.items()) {
            out[k] = _encode_value(store, v, path);
        }
        return out;
    }
    return value;
}

def encode_refs(store: RefStore, body: dict) -> dict {
    out = _encode_value(store, body, {});
    return out if isinstance(out, dict) else {};
}

def _decode_value(value: object, path: dict[int, bool]) -> object {
    if value is None or isinstance(value, (str, int, float, bool)) { return value; }
    if isinstance(value, list) {
        return [_decode_value(v, path) for v in value];
    }
    if isinstance(value, dict) {
        sig = id(value);
        if sig in path { return None; }
        path[sig] = True;
        out: dict[str, any] = {};
        for (k, v) in sorted(value.items()) {
            out[k] = _decode_value(v, path);
        }
        del path[sig];
        return out;
    }
    return value;
}

def decode_refs(store: RefStore, body: dict) -> dict {
    _ = store;
    out = _decode_value(body, {});
    return out if isinstance(out, dict) else {};
}

def shared_object_ids(store: RefStore, body: dict) -> list[str] {
    counts: dict[str, int] = {};
    stack: list[object] = [body];
    while stack {
        val = stack.pop();
        if isinstance(val, str) and val.startswith("@obj:") {
            oid = val[5:];
            counts[oid] = counts.get(oid, 0) + 1;
        } elif isinstance(val, list) {
            for item in val { stack.append(item); }
        } elif isinstance(val, dict) {
            for item in val.values() { stack.append(item); }
        }
    }
    return sorted([k for (k, n) in counts.items() if n > 1]);
}

test "shared refs encode without nulling duplicates" {
    store = load_ref_store([("S", {"id": "S", "n": 1})]);
    body = {"a": "@obj:S", "b": "@obj:S", "list": ["@obj:S", "@obj:S"]};
    enc = encode_refs(store, body);
    assert enc["a"] == {"id": "S", "n": 1};
    assert enc["b"] == {"id": "S", "n": 1};
    assert shared_object_ids(store, body) == ["S"];
}

test "true cycle yields null on back-edge" {
    store = load_ref_store([("cyc", {"name": "cyc", "self": "@obj:cyc"})]);
    enc = encode_refs(store, {"root": "@obj:cyc"});
    assert enc["root"]["self"] is None;
}

test "decode round-trip preserves structure" {
    store = load_ref_store([("T", {"id": "T"})]);
    enc = encode_refs(store, {"x": "@obj:T", "y": "@obj:T"});
    dec = decode_refs(store, enc);
    assert dec["x"] == dec["y"];
}

test "actor ref token passthrough" {
    store = load_ref_store([], [("lead", "node-1")]);
    enc = encode_refs(store, {"ref": "lead"});
    assert enc["ref"] == "@actor:node-1";
}
