"""Guard: voltrevo/wac#8."""

import from hashlib { sha256 }

obj TypeStore { has specs: dict[str, dict] = {}; has refs: list[tuple[str, str, str]] = []; }
node TypeNode { has tid: str; }
edge TypeRef { has slot: str; }

walker DepCloseWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";
    can step with TypeNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.origin { self.reached.append(here.tid); }
        visit [->:TypeRef:->] else { disengage; };
    }
}

def _find(tid: str) -> TypeNode | None {
    for n in [-->][?:TypeNode] { if n.tid == tid { return n; } }
    return None;
}

def load_types(specs: dict[str, dict], refs: list[tuple[str, str, str]]) -> TypeStore {
    mp: dict[str, TypeNode] = {};
    for tid in specs { fresh = TypeNode(tid=tid); root ++> fresh; mp[tid] = fresh; }
    for (src, slot, tgt) in refs {
        a = mp.get(src, None); b = mp.get(tgt, None);
        if a is not None and b is not None { a +>:TypeRef(slot=slot):+> b; }
    }
    return TypeStore(specs=specs, refs=refs);
}

def _canon(spec: dict, g: TypeStore, tid: str, visiting: dict[str, bool]) -> str {
    if tid in visiting { return "<cycle>"; }
    visiting[tid] = True;
    parts = [spec.get("kind", ""), spec.get("name", ""), str(spec.get("fields", []))];
    for (src, slot, tgt) in g.refs {
        if src == tid { parts.append(slot + ":" + _canon(g.specs.get(tgt, {}), g, tgt, visiting)); }
    }
    visiting[tid] = False;
    return "|".join(parts);
}

def type_digest(g: TypeStore, tid: str) -> str {
    if tid not in g.specs { return ""; }
    return sha256(_canon(g.specs[tid], g, tid, {}).encode()).hexdigest()[:16];
}

def same_identity(g: TypeStore, a: str, b: str) -> bool {
    if a not in g.specs or b not in g.specs { return False; }
    return type_digest(g, a) == type_digest(g, b);
}

def dependency_closure(g: TypeStore, tid: str) -> list[str] {
    anchor = _find(tid);
    if anchor is None { return []; }
    w = anchor spawn DepCloseWalk(claimed={}, reached=[], origin=tid);
    return sorted(w.reached);
}

test "identical specs share digest" {
    cfg = {"kind": "struct", "name": "Config", "fields": [("enabled", "bool")]};
    g = load_types({"a": cfg, "b": dict(cfg)}, []);
    assert same_identity(g, "a", "b");
}

test "name is part of identity" {
    g = load_types(
        {"a": {"kind": "struct", "name": "Metres", "fields": []}, "b": {"kind": "struct", "name": "Seconds", "fields": []}},
        [],
    );
    assert not same_identity(g, "a", "b");
}

test "diamond adversarial closure" {
    cfg = {"kind": "struct", "name": "T", "fields": []};
    g = load_types(
        {"hub": cfg, "left": cfg, "right": cfg, "cap": cfg},
        [("left", "to", "cap"), ("right", "to", "cap"), ("hub", "l", "left"), ("hub", "r", "right")],
    );
    assert dependency_closure(g, "hub") == ["cap", "left", "right"];
}

test "ref cycle terminates once" {
    cfg = {"kind": "struct", "name": "T", "fields": []};
    g = load_types(
        {"a": cfg, "b": cfg, "c": cfg},
        [("a", "n", "b"), ("b", "n", "c"), ("c", "n", "a")],
    );
    assert dependency_closure(g, "a") == ["b", "c"];
}
